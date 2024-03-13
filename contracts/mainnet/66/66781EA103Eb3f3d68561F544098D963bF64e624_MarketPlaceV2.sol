// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {VestingTerms} from "../VestingTerms.sol";

import {AccessHelper} from "../../utils/AccessHelper.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ADMIN_ROLE} from "../../utils/constants.sol";

import {MarketPlaceEvents} from "./utils/MarketPlaceEvents.sol";
import "./utils/MarketPlaceStructs.sol";

contract MarketPlaceV2 is AccessHelper, ReentrancyGuard, MarketPlaceEvents {
    uint256 public platformFee;
    address public feeRecipient;
    address public payableToken;
    uint256 public payableTokenDecimals;

    using Counters for Counters.Counter;
    Counters.Counter private contractCounter;
    Counters.Counter private globalSaleCounter;

    mapping(uint256 => FundingTermsContractInfo)
        public fundingTermsSupportedContracts;

    // user => token => number of orders
    mapping(address => mapping(address => uint256)) public userAsksCounter;
    mapping(address => mapping(address => uint256)) public userBidsCounter;

    // user => token => number of active orders
    mapping(address => mapping(address => uint256))
        public userActiveAsksCounter;
    mapping(address => mapping(address => uint256))
        public userActiveBidsCounter;

    // token =>  saleId => list struct
    mapping(address => mapping(uint256 => Order)) public askOrders;
    mapping(address => mapping(uint256 => Order)) public bidOrders;

    // token => tokens sales info struct
    mapping(address => TokenAsksInfo) private tokenAsksInfo;
    mapping(address => TokenBidsInfo) private tokenBidsInfo;

    mapping(address => bool) private vestingContractsAddresses;

    // function initialize(address _admin) public initializer {
    //     _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    //     _grantRole(ADMIN_ROLE, _admin);
    // }

    uint256 TOKEN_DECIMALS = 18;

    constructor(
        uint256 _platformFee,
        address _feeRecipient,
        address _payableToken,
        uint256 _payableTokenDecimals
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        require(
            platformFee <= 10000,
            "platform fee can't be more than 10 percent"
        );
        require(_feeRecipient != address(0), "fee recipient not valid address");
        require(
            _payableToken != address(0),
            "payable token is not valid address"
        );

        platformFee = _platformFee;
        feeRecipient = _feeRecipient;
        payableToken = _payableToken;
        payableTokenDecimals = _payableTokenDecimals;
    }

    function addSupportedFundingContractAddress(
        uint256 internalId,
        address _fundingTerms,
        string calldata _logoUrl,
        string calldata _symbol,
        address _tokenAddress
    ) external onlyAuthorized(ADMIN_ROLE) {
        require(
            vestingContractsAddresses[_fundingTerms] == false,
            "Vesting Contract already exists"
        );

        uint256 id = contractCounter.current();
        contractCounter.increment();

        fundingTermsSupportedContracts[id] = FundingTermsContractInfo({
            internalId: internalId,
            fundingTermsAddress: _fundingTerms,
            logoUrl: _logoUrl,
            symbol: _symbol,
            tokenAddress: _tokenAddress
        });

        vestingContractsAddresses[_fundingTerms] = true;
    }

    function listSupportedTokens()
        public
        view
        returns (FundingTermsContractInfo[] memory)
    {
        FundingTermsContractInfo[]
            memory result = new FundingTermsContractInfo[](
                contractCounter.current()
            );
        for (uint256 i = 0; i < contractCounter.current(); i++) {
            result[i] = fundingTermsSupportedContracts[i];
        }
        return result;
    }

    function listAvailableTokensForSale(
        address _user
    ) public view returns (UserAvailableTokensForSale[] memory) {
        address sender = _user;

        UserAvailableTokensForSale[]
            memory result = new UserAvailableTokensForSale[](
                contractCounter.current()
            );

        for (uint256 i = 0; i < contractCounter.current(); i++) {
            FundingTermsContractInfo
                memory contractInfo = fundingTermsSupportedContracts[i];

            VestingTerms fundingTerms = VestingTerms(
                contractInfo.fundingTermsAddress
            );

            (
                uint256 tokenBalance,
                uint256 lockedTokens,
                uint256 tokenReleased,
                address userAddress
            ) = fundingTerms.userBalances(sender);

            uint256 availableTokensAmount = 0;

            if ((tokenBalance - lockedTokens - tokenReleased) > 0) {
                availableTokensAmount =
                    tokenBalance -
                    lockedTokens -
                    tokenReleased;
            }

            result[i] = UserAvailableTokensForSale({
                internalId: contractInfo.internalId,
                fundingTermsAddress: contractInfo.fundingTermsAddress,
                logoUrl: contractInfo.logoUrl,
                symbol: contractInfo.symbol,
                tokenAddress: contractInfo.tokenAddress,
                availableTokensForSale: availableTokensAmount
            });
        }
        return result;
    }

    function checkFundingTermsValid(
        address _fundingTermsAddress
    ) internal view returns (bool exists) {
        for (uint256 i = 0; i < contractCounter.current(); i++) {
            if (
                fundingTermsSupportedContracts[i].fundingTermsAddress ==
                _fundingTermsAddress
            ) {
                return true;
            }
        }
        return false;
    }

    function createBid(
        address _fundingTermsAddress,
        uint256 _quantity,
        uint256 _fullPrice,
        address _payToken
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );

        require(
            checkFundingTermsValid(_fundingTermsAddress) == true,
            "address is not a supported contract"
        );

        require(_payToken != address(0), "invalid pay token address");
        require(
            _payToken == payableToken,
            "pay token not supported for this sale"
        );
        uint256 pricePerToken = getPricePerToken(
            _quantity,
            _fullPrice,
            payableTokenDecimals,
            TOKEN_DECIMALS
        );

        require(pricePerToken != 0, "price per token gt 0");

        require(_quantity > 0, "quantaty cannot be 0");
        require(_fullPrice > 0, "_fullPrice cannot be 0");

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);
        bool distributingStarted = fundingTerms.distributingStarted();
        require(
            distributingStarted == false,
            "cannot create bid while distributing"
        );

        address sender = msg.sender;
        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();

        IERC20(_payToken).transferFrom(sender, address(this), _fullPrice);

        TokenBidsInfo memory bidsInfo = tokenBidsInfo[tokenForSaleAddress];

        tokenBidsInfo[tokenForSaleAddress].activeBids = bidsInfo.activeBids + 1;
        tokenBidsInfo[tokenForSaleAddress].incrementalId =
            bidsInfo.incrementalId +
            1;

        userBidsCounter[sender][tokenForSaleAddress] =
            userBidsCounter[sender][tokenForSaleAddress] +
            1;

        userActiveBidsCounter[sender][tokenForSaleAddress] =
            userActiveBidsCounter[sender][tokenForSaleAddress] +
            1;

        Order memory bidOrder = Order({
            id: bidsInfo.incrementalId,
            fullPrice: _fullPrice,
            pricePerToken: pricePerToken,
            quantity: _quantity,
            sold: false,
            buyer: sender,
            seller: address(0),
            createdAt: block.timestamp,
            fulfilledAt: 0,
            fundingTermsAddress: _fundingTermsAddress,
            orderType: "BID"
        });

        bidOrders[tokenForSaleAddress][bidsInfo.incrementalId] = bidOrder;

        emit BidCreated(bidsInfo.incrementalId, tokenForSaleAddress, bidOrder);
    }

    function createAsk(
        address _fundingTermsAddress,
        uint256 _quantity,
        uint256 _fullPrice
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );
        require(
            checkFundingTermsValid(_fundingTermsAddress) == true,
            "address is not a supported contract"
        );
        require(_quantity > 0, "quantity must be greater than 0");
        require(_fullPrice > 0, "price must be greater than 0");

        uint256 pricePerToken = getPricePerToken(
            _quantity,
            _fullPrice,
            payableTokenDecimals,
            TOKEN_DECIMALS
        );

        require(pricePerToken != 0, "price per token gt 0");

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);
        bool distributingStarted = fundingTerms.distributingStarted();
        require(
            distributingStarted == false,
            "cannot create ask while distributing"
        );

        address sender = msg.sender;

        (
            uint256 tokenBalance,
            uint256 lockedTokens,
            uint256 tokenReleased,

        ) = fundingTerms.userBalances(sender);

        uint256 availableTokensAmount = 0;

        if ((tokenBalance - lockedTokens - tokenReleased) > 0) {
            availableTokensAmount = tokenBalance - lockedTokens - tokenReleased;
        }

        require(
            _quantity <= availableTokensAmount,
            "quantity is higher than available amount"
        );

        fundingTerms.lockTokens(sender, _quantity);

        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();

        userAsksCounter[sender][tokenForSaleAddress] =
            userAsksCounter[sender][tokenForSaleAddress] +
            1;

        userActiveAsksCounter[sender][tokenForSaleAddress] =
            userActiveAsksCounter[sender][tokenForSaleAddress] +
            1;

        TokenAsksInfo memory asksInfo = tokenAsksInfo[tokenForSaleAddress];

        tokenAsksInfo[tokenForSaleAddress].activeAsks = asksInfo.activeAsks + 1;
        tokenAsksInfo[tokenForSaleAddress].incrementalId =
            asksInfo.incrementalId +
            1;

        Order memory askOrder = Order({
            id: asksInfo.incrementalId,
            fullPrice: _fullPrice,
            pricePerToken: pricePerToken,
            quantity: _quantity,
            sold: false,
            seller: sender,
            buyer: address(0),
            createdAt: block.timestamp,
            fulfilledAt: 0,
            fundingTermsAddress: _fundingTermsAddress,
            orderType: "ASK"
        });

        askOrders[tokenForSaleAddress][asksInfo.incrementalId] = askOrder;

        emit AskCreated(asksInfo.incrementalId, tokenForSaleAddress, askOrder);
    }

    function listAskOrdersPerToken(
        address _tokenForSaleAddress
    ) public view returns (Order[] memory) {
        TokenAsksInfo memory tokenInfo = tokenAsksInfo[_tokenForSaleAddress];

        Order[] memory result = new Order[](tokenInfo.activeAsks);
        if (tokenInfo.activeAsks == 0) {
            return result;
        }

        uint256 resultCounter = 0;

        for (uint256 i = 0; i < tokenInfo.incrementalId; i++) {
            Order memory token = askOrders[_tokenForSaleAddress][i];

            if (token.sold == false && token.seller != address(0)) {
                result[resultCounter] = Order({
                    id: token.id,
                    quantity: token.quantity,
                    fullPrice: token.fullPrice,
                    pricePerToken: token.pricePerToken,
                    sold: token.sold,
                    seller: token.seller,
                    buyer: token.buyer,
                    createdAt: token.createdAt,
                    fulfilledAt: token.fulfilledAt,
                    fundingTermsAddress: token.fundingTermsAddress,
                    orderType: token.orderType
                });
                resultCounter = resultCounter + 1;
            }
        }

        return result;
    }

    function listBidOrdersPerToken(
        address _tokenForSaleAddress
    ) public view returns (Order[] memory) {
        TokenBidsInfo memory tokenInfo = tokenBidsInfo[_tokenForSaleAddress];

        Order[] memory result = new Order[](tokenInfo.activeBids);
        if (tokenInfo.activeBids == 0) {
            return result;
        }

        uint256 resultCounter = 0;

        for (uint256 i = 0; i < tokenInfo.incrementalId; i++) {
            Order memory bid = bidOrders[_tokenForSaleAddress][i];

            if (bid.sold == false && bid.buyer != address(0)) {
                result[resultCounter] = Order({
                    id: bid.id,
                    quantity: bid.quantity,
                    fullPrice: bid.fullPrice,
                    pricePerToken: bid.pricePerToken,
                    sold: bid.sold,
                    buyer: bid.buyer,
                    seller: bid.seller,
                    createdAt: bid.createdAt,
                    fulfilledAt: bid.fulfilledAt,
                    fundingTermsAddress: bid.fundingTermsAddress,
                    orderType: bid.orderType
                });
                resultCounter = resultCounter + 1;
            }
        }

        return result;
    }

    function cancelAskOrder(
        address _fundingTermsAddress,
        uint256 _saleId
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );

        require(
            checkFundingTermsValid(_fundingTermsAddress) == true,
            "address is not a supported contract"
        );

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);

        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();
        address sender = msg.sender;

        Order memory listedToken = askOrders[tokenForSaleAddress][_saleId];

        require(listedToken.seller == sender, "not ask owner");

        userAsksCounter[sender][tokenForSaleAddress] =
            userAsksCounter[sender][tokenForSaleAddress] -
            1;

        userActiveAsksCounter[sender][tokenForSaleAddress] =
            userActiveAsksCounter[sender][tokenForSaleAddress] -
            1;

        tokenAsksInfo[tokenForSaleAddress].activeAsks =
            tokenAsksInfo[tokenForSaleAddress].activeAsks -
            1;

        fundingTerms.unlockTokens(sender, listedToken.quantity);

        delete askOrders[tokenForSaleAddress][_saleId];
    }

    function cancelBidOrder(
        address _fundingTermsAddress,
        uint256 _bidId
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );

        require(
            checkFundingTermsValid(_fundingTermsAddress) == true,
            "address is not a supported contract"
        );

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);

        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();
        address sender = msg.sender;

        Order memory bid = bidOrders[tokenForSaleAddress][_bidId];

        require(bid.buyer == sender, "not bid owner");

        IERC20(payableToken).transfer(sender, bid.fullPrice);

        tokenBidsInfo[tokenForSaleAddress].activeBids =
            tokenBidsInfo[tokenForSaleAddress].activeBids -
            1;

        userBidsCounter[sender][tokenForSaleAddress] =
            userBidsCounter[sender][tokenForSaleAddress] -
            1;

        userActiveBidsCounter[sender][tokenForSaleAddress] =
            userActiveBidsCounter[sender][tokenForSaleAddress] -
            1;

        delete bidOrders[tokenForSaleAddress][_bidId];
    }

    function buy(
        address _fundingTermsAddress,
        uint256 _saleId,
        address _payToken,
        uint256 _price
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );

        require(
            checkFundingTermsValid(_fundingTermsAddress) == true,
            "address is not a supported contract"
        );

        require(_payToken != address(0), "invalid pay token address");
        require(
            _payToken == payableToken,
            "pay token not supported for this sale"
        );

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);

        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();
        address sender = msg.sender;

        Order storage listedToken = askOrders[tokenForSaleAddress][_saleId];

        require(listedToken.seller != address(0), "seller is not valid");
        require(_price == listedToken.fullPrice, "price is not correct");
        require(_saleId == listedToken.id, "id is not correct");

        listedToken.sold = true;
        listedToken.buyer = sender;
        listedToken.fulfilledAt = block.timestamp;
        uint256 totalPrice = _price;
        uint256 platformFeeTotal = calculatePlatformFee(_price);

        IERC20(_payToken).transferFrom(sender, feeRecipient, platformFeeTotal);

        IERC20(_payToken).transferFrom(
            sender,
            listedToken.seller,
            totalPrice - platformFeeTotal
        );

        fundingTerms.marketAskOrderFulFilled(
            listedToken.seller,
            sender,
            listedToken.quantity
        );

        address seller = listedToken.seller;

        tokenAsksInfo[tokenForSaleAddress].activeAsks =
            tokenAsksInfo[tokenForSaleAddress].activeAsks -
            1;

        userActiveAsksCounter[seller][tokenForSaleAddress] =
            userActiveAsksCounter[seller][tokenForSaleAddress] -
            1;

        emit OrderAccepted(listedToken.id, tokenForSaleAddress, listedToken);
    }

    function sell(
        address _fundingTermsAddress,
        uint256 _bidId,
        address _payToken,
        uint256 _fullPrice
    ) external nonReentrant {
        require(
            _fundingTermsAddress != address(0),
            "address cannot be null address"
        );

        require(
            checkFundingTermsValid(_fundingTermsAddress) == true,
            "address is not a supported contract"
        );

        require(_payToken != address(0), "invalid pay token address");
        require(
            _payToken == payableToken,
            "pay token not supported for this sale"
        );

        require(_fullPrice != 0, "price cannot be 0");

        VestingTerms fundingTerms = VestingTerms(_fundingTermsAddress);

        address tokenForSaleAddress = fundingTerms.tokenForSaleAddress();
        address sender = msg.sender;

        Order storage bid = bidOrders[tokenForSaleAddress][_bidId];

        require(bid.fullPrice == _fullPrice, "price is not correct");
        require(_bidId == bid.id, "bid id is not correct");

        (
            uint256 tokenBalance,
            uint256 lockedTokens,
            uint256 tokenReleased,

        ) = fundingTerms.userBalances(sender);

        uint256 availableTokensAmount = 0;

        if ((tokenBalance - lockedTokens - tokenReleased) > 0) {
            availableTokensAmount = tokenBalance - lockedTokens - tokenReleased;
        }

        require(
            bid.quantity <= availableTokensAmount,
            "quantity is higher than available amount"
        );

        bid.sold = true;
        bid.seller = sender;
        bid.fulfilledAt = block.timestamp;
        uint256 totalPrice = _fullPrice;
        uint256 platformFeeTotal = calculatePlatformFee(totalPrice);

        IERC20(_payToken).transfer(feeRecipient, platformFeeTotal);
        IERC20(_payToken).transfer(sender, totalPrice - platformFeeTotal);

        fundingTerms.marketBidOrderFulFilled(sender, bid.buyer, bid.quantity);

        tokenBidsInfo[tokenForSaleAddress].activeBids =
            tokenBidsInfo[tokenForSaleAddress].activeBids -
            1;

        address buyer = bid.buyer;

        userActiveBidsCounter[buyer][tokenForSaleAddress] =
            userActiveBidsCounter[buyer][tokenForSaleAddress] -
            1;

        emit OrderAccepted(bid.id, tokenForSaleAddress, bid);
    }

    function getActiveOrders(
        address _user,
        address _tokenForSaleAddress
    ) public view returns (Order[] memory) {
        uint256 numActiveAsks = userActiveAsksCounter[_user][
            _tokenForSaleAddress
        ];
        uint256 numActiveBids = userActiveBidsCounter[_user][
            _tokenForSaleAddress
        ];
        uint256 totalOrders = numActiveAsks + numActiveBids;
        Order[] memory userOrders = new Order[](totalOrders);

        TokenAsksInfo memory asksInfo = tokenAsksInfo[_tokenForSaleAddress];
        TokenBidsInfo memory bidsInfo = tokenBidsInfo[_tokenForSaleAddress];

        uint256 orderIndex = 0;

        if (asksInfo.activeAsks == 0 && bidsInfo.activeBids == 0) {
            return userOrders;
        }

        for (uint256 i = 0; i < asksInfo.incrementalId; i++) {
            Order memory ask = askOrders[_tokenForSaleAddress][i];
            if (ask.seller == _user && ask.sold == false) {
                userOrders[orderIndex] = Order({
                    id: ask.id,
                    quantity: ask.quantity,
                    fullPrice: ask.fullPrice,
                    pricePerToken: ask.pricePerToken,
                    sold: ask.sold,
                    seller: ask.seller,
                    buyer: ask.buyer,
                    createdAt: ask.createdAt,
                    fulfilledAt: ask.fulfilledAt,
                    fundingTermsAddress: ask.fundingTermsAddress,
                    orderType: ask.orderType
                });
                orderIndex = orderIndex + 1;
            }
        }

        for (uint256 i = 0; i < bidsInfo.incrementalId; i++) {
            Order memory bid = bidOrders[_tokenForSaleAddress][i];
            if (bid.buyer == _user && bid.sold == false) {
                userOrders[orderIndex] = Order({
                    id: bid.id,
                    quantity: bid.quantity,
                    fullPrice: bid.fullPrice,
                    pricePerToken: bid.pricePerToken,
                    sold: bid.sold,
                    seller: bid.seller,
                    buyer: bid.buyer,
                    createdAt: bid.createdAt,
                    fulfilledAt: bid.fulfilledAt,
                    fundingTermsAddress: bid.fundingTermsAddress,
                    orderType: bid.orderType
                });
                orderIndex = orderIndex + 1;
            }
        }

        return userOrders;
    }

    function getPricePerToken(
        uint256 _amount,
        uint256 _price,
        uint256 _payableTokenDecimals,
        uint256 _tokenDecimals
    ) internal pure returns (uint256) {
        uint256 decimals = _tokenDecimals - _payableTokenDecimals;
        uint256 normalizedPrice = _price * (10 ** decimals) * 1e18;

        uint256 pricePerToken = normalizedPrice / _amount;

        return pricePerToken / (10 ** decimals);
    }

    function updatePlatformFee(
        uint256 _platformFee
    ) external onlyAuthorized(ADMIN_ROLE) {
        require(_platformFee <= 10000, "can't more than 100 percent");
        platformFee = _platformFee;
    }

    function updateFeeRecipient(
        address _address
    ) external onlyAuthorized(ADMIN_ROLE) {
        require(_address != address(0), "invalid address");
        feeRecipient = _address;
    }

    function updatePayableToken(
        address _token,
        uint256 _decimals
    ) external onlyAuthorized(ADMIN_ROLE) {
        require(_token != address(0), "invalid address");
        require(_decimals != 0, "decimals gte 0");
        payableToken = _token;
        payableTokenDecimals = _decimals;
    }

    function calculatePlatformFee(
        uint256 _price
    ) public view returns (uint256) {
        return (_price * platformFee) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract AccessHelper is AccessControlEnumerable {
    modifier onlyAuthorized(bytes32 role) {
        _checkAuthorization(role);
        _;
    }

    function _checkAuthorization(bytes32 role) internal view {
        if (!hasRole(role, msg.sender)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(msg.sender), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessHelper} from "../utils/AccessHelper.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ADMIN_ROLE, MARKET_ROLE} from "../utils/constants.sol";

contract VestingTerms is AccessHelper, ReentrancyGuard {
    IERC20 private tokenForSaleContract;

    address public tokenForSaleAddress;
    bool public distributingStarted = false;

    struct UserInfo {
        uint256 tokenBalance;
        uint256 lockedTokens;
        uint256 tokenReleased;
        address userAddress;
    }

    mapping(address => UserInfo) public userBalances;
    address[] public userAddresses;
    mapping(address => bool) private addressExists;

    uint256 public vestingPeriod;
    uint256 public vestingMonths;
    uint8 public startVestingPercentage;
    uint256 public vestingStartTime;

    uint256 public unsoldTokensAmount;
    bool public unsoldTokensReleased = false;

    constructor(
        address _adminAddress,
        address _tokenForSaleAddress,
        uint256 _vestingMonths,
        uint8 _startVestingPercentage,
        address _marketAddress
    ) {
        require(_tokenForSaleAddress != address(0), "Address cannot be 0");
        require(_vestingMonths != 0, "Vesting period cannot be 0");

        tokenForSaleAddress = _tokenForSaleAddress;
        vestingPeriod = _vestingMonths * 30 * 24 * 60 * 60;
        vestingMonths = _vestingMonths;
        startVestingPercentage = _startVestingPercentage;

        tokenForSaleContract = IERC20(_tokenForSaleAddress);

        _grantRole(ADMIN_ROLE, _adminAddress);
        _grantRole(MARKET_ROLE, _marketAddress);
    }

    function startDistributing() external onlyAuthorized(ADMIN_ROLE) {
        require(distributingStarted == false, "distributing already started");
        vestingStartTime = block.timestamp;
        distributingStarted = true;
    }

    function calculateVestedAmount(
        uint256 elapsedTime,
        uint256 vestedAmount,
        uint256 releasedTokens,
        uint256 lockedTokens
    ) internal view returns (uint256) {
        if (elapsedTime >= vestingPeriod) {
            return vestedAmount - releasedTokens - lockedTokens;
        }

        uint256 availableAmount = vestedAmount - lockedTokens;
        uint256 startAmount = (availableAmount * startVestingPercentage) / 100;
        uint256 elapsedMonths = elapsedTime / 30 days;

        uint256 postStartAvailableAmount = availableAmount - startAmount;

        uint256 currentVestedAmount = (postStartAvailableAmount *
            elapsedMonths) / vestingMonths;

        return currentVestedAmount + startAmount - releasedTokens;
    }

    function getAvailableBalance(address _user) public view returns (uint256) {
        if (distributingStarted == false) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp - vestingStartTime;

        UserInfo memory memUserInfo = userBalances[_user];

        return
            calculateVestedAmount(
                elapsedTime,
                memUserInfo.tokenBalance,
                memUserInfo.tokenReleased,
                memUserInfo.lockedTokens
            );
    }

    function redeem(uint256 _amount) external nonReentrant {
        require(distributingStarted == true, "distributing has not started");
        address sender = msg.sender;

        uint256 elapsedTime = block.timestamp - vestingStartTime;

        UserInfo memory memUserInfo = userBalances[sender];

        uint256 availableBalance = calculateVestedAmount(
            elapsedTime,
            memUserInfo.tokenBalance,
            memUserInfo.tokenReleased,
            memUserInfo.lockedTokens
        );

        require(
            _amount <= availableBalance,
            "The requested amount exceeds the available balance"
        );

        require(
            memUserInfo.tokenReleased + _amount <= memUserInfo.tokenBalance,
            "The requested amount exceeds the total balance"
        );

        UserInfo storage userInfo = userBalances[sender];

        userInfo.tokenReleased += _amount;

        tokenForSaleContract.transfer(sender, _amount);
    }

    function lockTokens(
        address _user,
        uint256 _quantity
    ) external onlyAuthorized(MARKET_ROLE) {
        require(distributingStarted == false, "cannot lock while distributing");
        UserInfo memory memUserInfo = userBalances[_user];

        uint256 availableTokensAmount = 0;

        if (
            (memUserInfo.tokenBalance -
                memUserInfo.lockedTokens -
                memUserInfo.tokenReleased) > 0
        ) {
            availableTokensAmount =
                memUserInfo.tokenBalance -
                memUserInfo.lockedTokens -
                memUserInfo.tokenReleased;
        }

        require(
            _quantity <= availableTokensAmount,
            "quantity is higher than available amount"
        );

        UserInfo storage userInfo = userBalances[_user];
        userInfo.lockedTokens += _quantity;
    }

    function unlockTokens(
        address _user,
        uint256 _quantity
    ) external onlyAuthorized(MARKET_ROLE) {
        UserInfo memory memUserInfo = userBalances[_user];

        require(
            _quantity <= memUserInfo.lockedTokens,
            "quantity to unlock is higher than locked tokens"
        );

        UserInfo storage userInfo = userBalances[_user];
        userInfo.lockedTokens -= _quantity;
    }

    function marketAskOrderFulFilled(
        address _seller,
        address _buyer,
        uint256 _amount
    ) external onlyAuthorized(MARKET_ROLE) {
        require(_seller != address(0), "from address not valid");
        require(_buyer != address(0), "_to address not valid");
        require(_amount > 0, "amount must be higher than 0");

        UserInfo memory memUserInfo = userBalances[_seller];

        require(
            _amount <= memUserInfo.lockedTokens,
            "amount is greater than locked tokens"
        );
        require(
            _amount <= memUserInfo.tokenBalance,
            "mount is greater than total from balance"
        );

        UserInfo storage fromUserInfo = userBalances[_seller];
        fromUserInfo.lockedTokens -= _amount;
        fromUserInfo.tokenBalance -= _amount;

        UserInfo storage toUserInfo = userBalances[_buyer];
        toUserInfo.tokenBalance = toUserInfo.tokenBalance + _amount;

        if (!addressExists[_buyer]) {
            userAddresses.push(_buyer);
            addressExists[_buyer] = true;
        }
    }

    function marketBidOrderFulFilled(
        address _seller,
        address _buyer,
        uint256 _amount
    ) external onlyAuthorized(MARKET_ROLE) {
        require(_seller != address(0), "from address not valid");
        require(_buyer != address(0), "_to address not valid");
        require(_amount > 0, "amount must be higher than 0");

        UserInfo memory memUserInfo = userBalances[_seller];

        uint256 availableTokensAmount = 0;

        if (
            (memUserInfo.tokenBalance -
                memUserInfo.lockedTokens -
                memUserInfo.tokenReleased) > 0
        ) {
            availableTokensAmount =
                memUserInfo.tokenBalance -
                memUserInfo.lockedTokens -
                memUserInfo.tokenReleased;
        }

        require(
            _amount <= availableTokensAmount,
            "amount is greater than locked tokens"
        );

        UserInfo storage fromUserInfo = userBalances[_seller];
        fromUserInfo.tokenBalance -= _amount;

        UserInfo storage toUserInfo = userBalances[_buyer];
        toUserInfo.tokenBalance = toUserInfo.tokenBalance + _amount;

        if (!addressExists[_buyer]) {
            userAddresses.push(_buyer);
            addressExists[_buyer] = true;
        }
    }

    function updateUserBalances(
        UserInfo[] memory usersInfo
    ) public onlyAuthorized(ADMIN_ROLE) {
        for (uint256 i = 0; i < usersInfo.length; i++) {
            UserInfo memory info = usersInfo[i];
            UserInfo storage user = userBalances[info.userAddress];

            user.tokenBalance = info.tokenBalance;
            user.lockedTokens = 0;
            user.tokenReleased = 0;
            user.userAddress = info.userAddress;

            if (!addressExists[info.userAddress]) {
                userAddresses.push(info.userAddress);
                addressExists[info.userAddress] = true;
            }
        }
    }

    function getTotalUsers() public view returns (uint256) {
        return userAddresses.length;
    }

    function getUsers(
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (address[] memory) {
        require(
            startIndex < endIndex,
            "Invalid index: startIndex must be less than endIndex"
        );
        require(endIndex <= userAddresses.length, "Index out of bounds");

        uint256 length = endIndex - startIndex;
        address[] memory usersInfo = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            usersInfo[i] = userAddresses[startIndex + i];
        }

        return usersInfo;
    }

    function releaseUnsoldTokens() external onlyAuthorized(ADMIN_ROLE) {
        require(
            unsoldTokensAmount <= tokenForSaleContract.balanceOf(address(this)),
            "unsoldTokensAmount higher than contract balance"
        );

        require(
            unsoldTokensReleased == false,
            "unsold tokens already released"
        );

        tokenForSaleContract.transfer(msg.sender, unsoldTokensAmount);
        unsoldTokensReleased = true;
    }

    function setUnsoldTokensAmount(
        uint256 _amount
    ) external onlyAuthorized(ADMIN_ROLE) {
        unsoldTokensAmount = _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// access roles

bytes32 constant TOKEN_PROVIDER_ROLE = keccak256("TOKEN_PROVIDER_ROLE");
bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 constant MARKET_ROLE = keccak256("MARKET_ROLE");


//test 
bytes32 constant GREETER_ROLE = keccak256("GREETER_ROLE");

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./MarketPlaceStructs.sol";

abstract contract MarketPlaceEvents {
    event AskCreated(
        uint256 indexed id,
        address indexed tokenAddress,
        Order askOrder
    );

    event BidCreated(
        uint256 indexed id,
        address indexed tokenAddress,
        Order bidOrder
    );

    event OrderAccepted (
        uint256 indexed id,
        address indexed tokenAddress,
        Order askOrder
    );

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


struct FundingTermsContractInfo {
    uint256 internalId;
    address fundingTermsAddress;
    string logoUrl;
    string symbol;
    address tokenAddress;
}

struct UserAvailableTokensForSale {
    uint256 internalId;
    address fundingTermsAddress;
    string logoUrl;
    string symbol;
    address tokenAddress;
    uint256 availableTokensForSale;
}

struct Order {
    uint256 id;
    uint256 quantity;
    uint256 fullPrice;
    uint256 pricePerToken;
    bool sold;
    address seller;
    address buyer;
    address fundingTermsAddress;
    uint256 createdAt;
    uint256 fulfilledAt;
    string orderType;  
}

struct TokenAsksInfo {
    uint256 activeAsks;
    uint256 incrementalId;
}

struct TokenBidsInfo {
    uint256 activeBids;
    uint256 incrementalId;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}