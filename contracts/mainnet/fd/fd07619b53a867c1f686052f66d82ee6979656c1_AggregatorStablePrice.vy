#pragma version 0.3.10
"""
@title AggregatorStablePrice
@author Curve.Fi
@license Copyright (c) Curve.Fi, 2020-2024 - all rights reserved
@dev Returns price of stablecoin in "dollars" based on multiple AMM prices
     Version 3 - for use with StableSwap-ng pools
"""


interface Stableswap:
    def price_oracle(i: uint256=0) -> uint256: view
    def coins(i: uint256) -> address: view
    def get_virtual_price() -> uint256: view
    def totalSupply() -> uint256: view

interface CoreOwner:
    def owner() -> address: view
    def stableCoin() -> address: view
    def feeReceiver() -> address: view


struct PricePair:
    pool: Stableswap
    is_inverse: bool
    include_index: bool


event AddPricePair:
    n: uint256
    pool: Stableswap
    is_inverse: bool

event RemovePricePair:
    n: uint256

event MovePricePair:
    n_from: uint256
    n_to: uint256


MAX_PAIRS: constant(uint256) = 20
MIN_LIQUIDITY: constant(uint256) = 100_000 * 10**18  # Only take into account pools with enough liquidity
TVL_MA_TIME: public(constant(uint256)) = 50000  # s

CORE_OWNER: public(immutable(CoreOwner))
STABLECOIN: public(immutable(address))
SIGMA: public(immutable(uint256))

price_pairs: public(PricePair[MAX_PAIRS])
n_price_pairs: uint256

last_timestamp: public(uint256)
last_tvl: public(uint256[MAX_PAIRS])
last_price: public(uint256)


@external
def __init__(core: CoreOwner, stable: address, sigma: uint256):
    """
    @notice Contract constructor
    @param core `DFMProtocolCore` address. Ownership is inherited from this contract.
    @param stable Address of the protocol stablecoin.
    @param sigma Sigma value.
    """
    CORE_OWNER = core
    STABLECOIN = stable
    SIGMA = sigma  # The change is so rare that we can change the whole thing altogether

    self.last_price = 10**18
    self.last_timestamp = block.timestamp


# --- external view functions ---

@view
@external
def ema_tvl() -> DynArray[uint256, MAX_PAIRS]:
    return self._ema_tvl()


@view
@external
def price() -> uint256:
    return self._price(self._ema_tvl())


# --- external unguarded functions ---

@external
def price_w() -> uint256:
    if self.last_timestamp == block.timestamp:
        return self.last_price
    else:
        ema_tvl: DynArray[uint256, MAX_PAIRS] = self._ema_tvl()
        self.last_timestamp = block.timestamp
        for i in range(MAX_PAIRS):
            if i == len(ema_tvl):
                break
            self.last_tvl[i] = ema_tvl[i]
        p: uint256 = self._price(ema_tvl)
        self.last_price = p
        return p


# --- external owner-only functions ---

@external
def add_price_pair(_pool: Stableswap):
    """
    @notice Add a Curve pool to include in the aggregate price
    @param _pool Curve stableswap address
    """
    assert msg.sender == CORE_OWNER.owner()
    price_pair: PricePair = empty(PricePair)
    price_pair.pool = _pool
    success: bool = raw_call(
        _pool.address, _abi_encode(convert(0, uint256), method_id=method_id("price_oracle(uint256)")),
        revert_on_failure=False
    )
    if success:
        price_pair.include_index = True
    coins: address[2] = [_pool.coins(0), _pool.coins(1)]
    if coins[0] == STABLECOIN:
        price_pair.is_inverse = True
    else:
        assert coins[1] == STABLECOIN
    n: uint256 = self.n_price_pairs
    self.price_pairs[n] = price_pair  # Should revert if too many pairs
    self.last_tvl[n] = _pool.totalSupply()
    self.n_price_pairs = n + 1
    log AddPricePair(n, _pool, price_pair.is_inverse)


@external
def remove_price_pair(n: uint256):
    """
    @notice Remove a pool from the price aggregation
    @param n Index of the pool within `price_pairs`
    """
    assert msg.sender == CORE_OWNER.owner()
    n_max: uint256 = self.n_price_pairs - 1
    assert n <= n_max

    if n < n_max:
        self.price_pairs[n] = self.price_pairs[n_max]
        self.last_tvl[n] = self.last_tvl[n_max]
        log MovePricePair(n_max, n)
    self.price_pairs[n_max] = empty(PricePair)
    self.last_tvl[n_max] = 0
    self.n_price_pairs = n_max
    log RemovePricePair(n)


# --- internal functions ---

@view
@internal
def exp(power: int256) -> uint256:
    if power <= -41446531673892821376:
        return 0

    if power >= 135305999368893231589:
        raise "exp overflow"

    x: int256 = unsafe_div(unsafe_mul(power, 2**96), 10**18)

    k: int256 = unsafe_div(
        unsafe_add(
            unsafe_div(unsafe_mul(x, 2**96), 54916777467707473351141471128),
            2**95),
        2**96)
    x = unsafe_sub(x, unsafe_mul(k, 54916777467707473351141471128))

    y: int256 = unsafe_add(x, 1346386616545796478920950773328)
    y = unsafe_add(unsafe_div(unsafe_mul(y, x), 2**96), 57155421227552351082224309758442)
    p: int256 = unsafe_sub(unsafe_add(y, x), 94201549194550492254356042504812)
    p = unsafe_add(unsafe_div(unsafe_mul(p, y), 2**96), 28719021644029726153956944680412240)
    p = unsafe_add(unsafe_mul(p, x), (4385272521454847904659076985693276 * 2**96))

    q: int256 = x - 2855989394907223263936484059900
    q = unsafe_add(unsafe_div(unsafe_mul(q, x), 2**96), 50020603652535783019961831881945)
    q = unsafe_sub(unsafe_div(unsafe_mul(q, x), 2**96), 533845033583426703283633433725380)
    q = unsafe_add(unsafe_div(unsafe_mul(q, x), 2**96), 3604857256930695427073651918091429)
    q = unsafe_sub(unsafe_div(unsafe_mul(q, x), 2**96), 14423608567350463180887372962807573)
    q = unsafe_add(unsafe_div(unsafe_mul(q, x), 2**96), 26449188498355588339934803723976023)

    return shift(
        unsafe_mul(convert(unsafe_div(p, q), uint256), 3822833074963236453042738258902158003155416615667),
        unsafe_sub(k, 195))


@view
@internal
def _ema_tvl() -> DynArray[uint256, MAX_PAIRS]:
    tvls: DynArray[uint256, MAX_PAIRS] = []
    last_timestamp: uint256 = self.last_timestamp
    alpha: uint256 = 10**18
    if last_timestamp < block.timestamp:
        alpha = self.exp(- convert((block.timestamp - last_timestamp) * 10**18 / TVL_MA_TIME, int256))
    n_price_pairs: uint256 = self.n_price_pairs

    for i in range(MAX_PAIRS):
        if i == n_price_pairs:
            break
        tvl: uint256 = self.last_tvl[i]
        if alpha != 10**18:
            # alpha = 1.0 when dt = 0
            # alpha = 0.0 when dt = inf
            new_tvl: uint256 = self.price_pairs[i].pool.totalSupply()  # We don't do virtual price here to save on gas
            tvl = (new_tvl * (10**18 - alpha) + tvl * alpha) / 10**18
        tvls.append(tvl)

    return tvls


@view
@internal
def _price(tvls: DynArray[uint256, MAX_PAIRS]) -> uint256:
    n: uint256 = self.n_price_pairs
    prices: uint256[MAX_PAIRS] = empty(uint256[MAX_PAIRS])
    D: uint256[MAX_PAIRS] = empty(uint256[MAX_PAIRS])
    Dsum: uint256 = 0
    DPsum: uint256 = 0
    for i in range(MAX_PAIRS):
        if i == n:
            break
        price_pair: PricePair = self.price_pairs[i]
        pool_supply: uint256 = tvls[i]
        if pool_supply >= MIN_LIQUIDITY:
            p: uint256 = 0
            if price_pair.include_index:
                p = price_pair.pool.price_oracle(0)
            else:
                p = price_pair.pool.price_oracle()
            if price_pair.is_inverse:
                p = 10**36 / p
            prices[i] = p
            D[i] = pool_supply
            Dsum += pool_supply
            DPsum += pool_supply * p
    if Dsum == 0:
        return 10**18  # Placeholder for no active pools
    p_avg: uint256 = DPsum / Dsum
    e: uint256[MAX_PAIRS] = empty(uint256[MAX_PAIRS])
    e_min: uint256 = max_value(uint256)
    for i in range(MAX_PAIRS):
        if i == n:
            break
        p: uint256 = prices[i]
        e[i] = (max(p, p_avg) - min(p, p_avg))**2 / (SIGMA**2 / 10**18)
        e_min = min(e[i], e_min)
    wp_sum: uint256 = 0
    w_sum: uint256 = 0
    for i in range(MAX_PAIRS):
        if i == n:
            break
        w: uint256 = D[i] * self.exp(-convert(e[i] - e_min, int256)) / 10**18
        w_sum += w
        wp_sum += w * prices[i]
    return wp_sum / w_sum