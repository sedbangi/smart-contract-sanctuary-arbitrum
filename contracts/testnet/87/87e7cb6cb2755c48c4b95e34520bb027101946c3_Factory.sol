// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "./UserConfig.sol";
import "./Endpoint.sol";
import "./Channel.sol";

import "./eco/Oracle.sol";
import "./eco/Relayer.sol";

contract Factory {
    event Deployed(address config, address channel, address endpoint);
    bytes32 public immutable SALT;
    address public immutable DEPLOYER;

    UserConfig public config;
    Channel public channel;
    Endpoint public endpoint;

    constructor(address deployer, bytes32 salt) {
        SALT = salt;
        DEPLOYER = deployer;
    }

    function deploy() external returns (address, address, address) {
        require(msg.sender == DEPLOYER, "!deployer");

        config = new UserConfig{salt: SALT}();
        config.changeSetter(DEPLOYER);

        channel = new Channel{salt: SALT}();
        endpoint = new Endpoint{salt: SALT}();
        channel.init(address(config), address(endpoint));
        endpoint.init(address(config), address(channel));

        require(channel.CONFIG() == address(config));
        require(channel.ENDPOINT() == address(endpoint));
        require(endpoint.CONFIG() == address(config));
        require(endpoint.CHANNEL() == address(channel));

        emit Deployed(address(config), address(channel), address(endpoint));
        return (address(config), address(channel), address(endpoint));
    }
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "./interfaces/IUserConfig.sol";

/// @title UserConfig
/// @notice User config could select their own relayer and oracle.
/// The default configuration is used by default.
/// @dev Only setter could set default config.
contract UserConfig {
    /// @dev Setter address.
    address public setter;
    /// @dev ua => config.
    mapping(address => Config) public appConfig;
    /// @dev Default config.
    Config public defaultConfig;

    /// @dev Notifies an observer that the default config has set.
    /// @param oracle Default oracle.
    /// @param relayer Default relayer.
    event SetDefaultConfig(address oracle, address relayer);
    /// @dev Notifies an observer that the user application config has updated.
    /// @param ua User application contract address.
    /// @param oracle Oracle which user application.
    /// @param relayer Relayer which user application choose.
    event AppConfigUpdated(address indexed ua, address oracle, address relayer);

    modifier onlySetter() {
        require(msg.sender == setter, "!auth");
        _;
    }

    constructor() {
        setter = msg.sender;
    }

    /// @dev Change setter.
    /// @notice Only current setter could call.
    /// @param setter_ New setter.
    function changeSetter(address setter_) external onlySetter {
        setter = setter_;
    }

    /// @dev Set default config for all application.
    /// @notice Only setter could call.
    /// @param oracle Default oracle.
    /// @param relayer Default relayer.
    function setDefaultConfig(address oracle, address relayer) external onlySetter {
        defaultConfig = Config(oracle, relayer);
        emit SetDefaultConfig(oracle, relayer);
    }

    /// @dev Fetch user application config.
    /// @notice If user application has not configured, then the default config is used.
    /// @param ua User application contract address.
    /// @return user application config.
    function getAppConfig(address ua) external view returns (Config memory) {
        Config memory c = appConfig[ua];

        if (c.relayer == address(0x0)) {
            c.relayer = defaultConfig.relayer;
        }

        if (c.oracle == address(0x0)) {
            c.oracle = defaultConfig.oracle;
        }

        return c;
    }

    /// @notice Set user application config.
    /// @param oracle Oracle which user application.
    /// @param relayer Relayer which user application choose.
    function setAppConfig(address oracle, address relayer) external {
        appConfig[msg.sender] = Config(oracle, relayer);
        emit AppConfigUpdated(msg.sender, oracle, relayer);
    }
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "./Common.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IChannel.sol";
import "./interfaces/IRelayer.sol";
import "./interfaces/IUserConfig.sol";
import "./security/ReentrancyGuard.sol";
import "./security/ExcessivelySafeCall.sol";

/// @title Endpoint
/// @notice An endpoint is a type of network node for cross-chain communication.
/// It is an interface exposed by a communication channel.
/// @dev An endpoint is associated with an immutable channel and user configuration.
contract Endpoint is ReentrancyGuard {
    using ExcessivelySafeCall for address;

    /// msgHash => isFailed
    mapping(bytes32 => bool) public fails;

    /// @dev User config address.
    address public CONFIG;
    /// @dev Channel address.
    address public CHANNEL;

    /// @dev Factory immutable address.
    address public immutable FACTORY;

    /// @dev Notifies an observer that the failed message has been cleared.
    /// @param msgHash Hash of the message.
    event ClearFailedMessage(bytes32 indexed msgHash);
    /// @dev Notifies an observer that the failed message has been retried.
    /// @param msgHash Hash of the message.
    /// @param dispatchResult Result of the message dispatch.
    event RetryFailedMessage(bytes32 indexed msgHash, bool dispatchResult);

    /// @dev Init code.
    constructor() {
        FACTORY = msg.sender;
    }

    /// @dev Called once by the factory at time of deployment
    /// @param config User config immutable address.
    /// @param channel Channel immutable address.
    function init(address config, address channel) external {
        require(FACTORY == msg.sender, "!factory");
        CONFIG = config;
        CHANNEL = channel;
    }

    /// @dev Send a cross-chain message over the endpoint.
    /// @notice follow https://eips.ethereum.org/EIPS/eip-5750
    /// @param toChainId The Message destination chain id.
    /// @param to User application contract address which receive the message.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param params General extensibility for relayer to custom functionality.
    function send(uint256 toChainId, address to, bytes calldata encoded, bytes calldata params)
        external
        payable
        sendNonReentrant
        returns (bytes32)
    {
        // user application address.
        address ua = msg.sender;
        // fetch user application's config.
        Config memory uaConfig = IUserConfig(CONFIG).getAppConfig(ua);
        // send message by channel, return the hash of the message as id.
        bytes32 msgHash = IChannel(CHANNEL).sendMessage(ua, toChainId, to, encoded);

        // handle relayer fee
        uint256 relayerFee = _handleRelayer(uaConfig.relayer, msgHash, toChainId, ua, encoded.length, params);
        // handle oracle fee
        uint256 oracleFee = _handleOracle(uaConfig.oracle, msgHash, toChainId, ua);

        //refund
        if (msg.value > relayerFee + oracleFee) {
            uint256 refund = msg.value - (relayerFee + oracleFee);
            (bool success,) = ua.call{value: refund}("");
            require(success, "!refund");
        }

        return msgHash;
    }

    /// @notice Get a quote in source native gas, for the amount that send() requires to pay for message delivery.
    /// @param toChainId The Message destination chain id.
    //  @param to User application contract address which receive the message.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param params General extensibility for relayer to custom functionality.
    function fee(uint256 toChainId, address, /*to*/ bytes calldata encoded, bytes calldata params)
        external
        view
        returns (uint256)
    {
        address ua = msg.sender;
        Config memory uaConfig = IUserConfig(CONFIG).getAppConfig(ua);
        uint256 relayerFee = IRelayer(uaConfig.relayer).fee(toChainId, ua, encoded.length, params);
        uint256 oracleFee = IOracle(uaConfig.oracle).fee(toChainId, ua);
        return relayerFee + oracleFee;
    }

    function _handleRelayer(
        address relayer,
        bytes32 msgHash,
        uint256 toChainId,
        address ua,
        uint256 size,
        bytes calldata params
    ) internal returns (uint256) {
        uint256 relayerFee = IRelayer(relayer).fee(toChainId, ua, size, params);
        IRelayer(relayer).assign{value: relayerFee}(msgHash, params);
        return relayerFee;
    }

    function _handleOracle(address oracle, bytes32 msgHash, uint256 toChainId, address ua) internal returns (uint256) {
        uint256 oracleFee = IOracle(oracle).fee(toChainId, ua);
        IOracle(oracle).assign{value: oracleFee}(msgHash);
        return oracleFee;
    }

    /// @dev Recv verified message from Channel and dispatch to destination user application address.
    /// @notice Only channel could call this function.
    /// @param message Verified receive message info.
    /// @param gasLimit The gas limit of message execute.
    /// @return dispatchResult Result of the message dispatch.
    function recv(Message calldata message, uint256 gasLimit) external recvNonReentrant returns (bool dispatchResult) {
        require(msg.sender == CHANNEL, "!auth");
        bytes32 msgHash = hash(message);
        dispatchResult = _dispatch(message, msgHash, gasLimit);
        if (!dispatchResult) {
            fails[msgHash] = true;
        }
    }

    /// @dev Retry failed message.
    /// @param message Failed message info.
    /// @return dispatchResult Result of the message dispatch.
    function retryFailedMessage(Message calldata message) external recvNonReentrant returns (bool dispatchResult) {
        bytes32 msgHash = hash(message);
        require(fails[msgHash] == true, "!failed");
        dispatchResult = _dispatch(message, msgHash, gasleft());
        if (dispatchResult) {
            delete fails[msgHash];
        }
        emit RetryFailedMessage(msgHash, dispatchResult);
    }

    /// @dev Retry failed message.
    /// @notice Only message.to could clear this message.
    /// @param message Failed message info.
    function clearFailedMessage(Message calldata message) external {
        bytes32 msgHash = hash(message);
        require(fails[msgHash] == true, "!failed");
        require(message.to == msg.sender, "!auth");
        delete fails[msgHash];
        emit ClearFailedMessage(msgHash);
    }

    /// @dev Dispatch the cross chain message.
    function _dispatch(Message memory message, bytes32 msgHash, uint256 gasLimit)
        private
        returns (bool dispatchResult)
    {
        // Deliver the message to user application contract address.
        (dispatchResult,) = message.to.excessivelySafeCall(
            gasLimit, 0, abi.encodePacked(message.encoded, msgHash, uint256(message.fromChainId), message.from)
        );
    }
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "./interfaces/IEndpoint.sol";
import "./interfaces/IUserConfig.sol";
import "./interfaces/IVerifier.sol";
import "./imt/IncrementalMerkleTree.sol";

/// @title Channel
/// @notice A channel is a logical connection over cross-chain network.
/// It used for cross-chain message transfer.
/// - Accepts messages to be dispatched to remote chains,
///   constructs a Merkle tree of the messages.
/// - Dispatches verified messages from source chains.
/// @dev Messages live in an incremental merkle tree (imt)
/// > A Merkle tree is a binary and complete tree decorated with
/// > the Merkle (hash) attribute.
contract Channel {
    using IncrementalMerkleTree for IncrementalMerkleTree.Tree;

    /// @dev Incremental merkle tree root which all message hashes live in leafs.
    bytes32 public root;
    /// @dev Incremental merkle tree.
    IncrementalMerkleTree.Tree private imt;
    /// @dev msgHash => isDispathed.
    mapping(bytes32 => bool) public dones;

    /// @dev User config address.
    address public CONFIG;
    /// @dev Endpoint address.
    address public ENDPOINT;

    /// @dev Factory immutable address.
    address public immutable FACTORY;
    address private immutable _self = address(this);

    /// @dev Notifies an observer that the message has been accepted.
    /// @param msgHash Hash of the message.
    /// @param root New incremental merkle tree root after a new message inserted.
    /// @param message Accepted message info.
    event MessageAccepted(bytes32 indexed msgHash, bytes32 root, Message message);
    /// @dev Notifies an observer that the message has been dispatched.
    /// @param msgHash Hash of the message.
    /// @param dispatchResult The message dispatch result.
    event MessageDispatched(bytes32 indexed msgHash, bool dispatchResult);

    modifier onlyEndpoint() {
        require(msg.sender == ENDPOINT, "!endpoint");
        _;
    }

    /// @dev Init code.
    constructor() {
        // init with empty tree
        root = 0x27ae5ba08d7291c96c8cbddcc148bf48a6d68c7974b94356f53754ef6171d757;
        FACTORY = msg.sender;
    }

    /// @dev Called once by the factory at time of deployment
    /// @param config User config immutable address.
    /// @param endpoint Endpoint immutable address.
    function init(address config, address endpoint) external {
        require(FACTORY == msg.sender, "!factory");
        CONFIG = config;
        ENDPOINT = endpoint;
    }

    /// @dev Fetch local chain id.
    /// @return chainId Local chain id.
    function LOCAL_CHAINID() public view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    /// @dev Send message.
    /// @notice Only endpoint could call this function.
    /// @param from User application contract address which send the message.
    /// @param toChainId The Message destination chain id.
    /// @param to User application contract address which receive the message.
    /// @param encoded The calldata which encoded by ABI Encoding.
    function sendMessage(address from, uint256 toChainId, address to, bytes calldata encoded)
        external
        onlyEndpoint
        returns (bytes32)
    {
        // only cross-chain message
        require(toChainId != LOCAL_CHAINID(), "!cross-chain");
        // get this message leaf index.
        uint256 index = messageCount();
        // constuct message object.
        Message memory message = Message({
            channel: _self,
            index: index,
            fromChainId: LOCAL_CHAINID(),
            from: from,
            toChainId: toChainId,
            to: to,
            encoded: encoded
        });
        // hash the message.
        bytes32 msgHash = hash(message);
        // insert msg hash to imt.
        imt.insert(msgHash);
        // update new imt.root to root storage.
        root = imt.root();

        // emit accepted message event.
        emit MessageAccepted(msgHash, root, message);

        // return this message hash.
        return msgHash;
    }

    /// @dev Receive messages.
    /// @notice Only message.to's config relayer could relayer this message.
    /// @param message Received message info.
    /// @param proof Message proof of this message.
    /// @param gasLimit The gas limit of message execute.
    function recvMessage(Message calldata message, bytes calldata proof, uint256 gasLimit) external {
        // get message.to user config.
        Config memory uaConfig = IUserConfig(CONFIG).getAppConfig(message.to);
        // only the config relayer could relay this message.
        require(uaConfig.relayer == msg.sender, "!auth");

        // hash the message.
        bytes32 msgHash = hash(message);
        // verify message by the config oracle.
        require(IVerifier(uaConfig.oracle).verifyMessageProof(message.fromChainId, msgHash, proof), "!proof");

        // check destination chain id is correct.
        require(LOCAL_CHAINID() == message.toChainId, "!toChainId");
        // check the message is not dispatched.
        require(dones[msgHash] == false, "done");
        // set the message is dispatched.
        dones[msgHash] = true;

        // then, dispatch message to endpoint.
        bool dispatchResult = IEndpoint(ENDPOINT).recv(message, gasLimit);
        // emit dispatched message event.
        emit MessageDispatched(msgHash, dispatchResult);
    }

    /// @dev Fetch the messages count of incremental merkle tree.
    function messageCount() public view returns (uint256) {
        return imt.count;
    }

    /// @dev Fetch the branch of incremental merkle tree.
    function imtBranch() public view returns (bytes32[32] memory) {
        return imt.branch;
    }
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "../Verifier.sol";
import "../interfaces/IFeedOracle.sol";

contract Oracle is Verifier {
    event Assigned(bytes32 indexed msgHash, uint256 fee);
    event SetFee(uint256 indexed chainId, uint256 fee);
    event SetDapi(uint256 indexed chainId, address dapi);
    event SetApproved(address operator, bool approve);

    address public immutable ENDPOINT;
    address public owner;

    // chainId => price
    mapping(uint256 => uint256) public feeOf;
    // chainId => dapi
    mapping(uint256 => address) public dapiOf;
    mapping(address => bool) public approvedOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier onlyApproved() {
        require(isApproved(msg.sender), "!approve");
        _;
    }

    constructor(address dao, address endpoint) {
        ENDPOINT = endpoint;
        owner = dao;
    }

    receive() external payable {}

    function changeOwner(address owner_) external onlyOwner {
        owner = owner_;
    }

    function isApproved(address operator) public view returns (bool) {
        return approvedOf[operator];
    }

    function setApproved(address operator, bool approve) public onlyOwner {
        approvedOf[operator] = approve;
        emit SetApproved(operator, approve);
    }

    function withdraw(address to, uint256 amount) external onlyApproved {
        (bool success,) = to.call{value: amount}("");
        require(success, "!withdraw");
    }

    function setFee(uint256 chainId, uint256 fee_) external onlyApproved {
        feeOf[chainId] = fee_;
        emit SetFee(chainId, fee_);
    }

    function setDapi(uint256 chainId, address dapi) external onlyOwner {
        dapiOf[chainId] = dapi;
        emit SetDapi(chainId, dapi);
    }

    function fee(uint256 toChainId, address /*ua*/ ) public view returns (uint256) {
        return feeOf[toChainId];
    }

    function assign(bytes32 msgHash) external payable {
        require(msg.sender == ENDPOINT, "!enpoint");
        emit Assigned(msgHash, msg.value);
    }

    function merkleRoot(uint256 chainId, uint256 /*blockNumber*/ ) public view override returns (bytes32) {
        address dapi = dapiOf[chainId];
        return IFeedOracle(dapi).messageRoot();
    }
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "../interfaces/IChannel.sol";

contract Relayer {
    event Assigned(bytes32 indexed msgHash, uint256 fee, bytes parmas);
    event SetDstPrice(uint256 indexed chainId, uint128 dstPriceRatio, uint128 dstGasPriceInWei);
    event SetDstConfig(uint256 indexed chainId, uint64 baseGas, uint64 gasPerByte);
    event SetApproved(address operator, bool approve);

    struct DstPrice {
        uint128 dstPriceRatio; // dstPrice / localPrice * 10^10
        uint128 dstGasPriceInWei;
    }

    struct DstConfig {
        uint64 baseGas;
        uint64 gasPerByte;
    }

    address public immutable ENDPOINT;
    address public immutable CHANNEL;
    address public owner;

    // chainId => price
    mapping(uint256 => DstPrice) public priceOf;
    mapping(uint256 => DstConfig) public configOf;
    mapping(address => bool) public approvedOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier onlyApproved() {
        require(isApproved(msg.sender), "!approve");
        _;
    }

    constructor(
        address dao,
        address endpoint,
        address channel
    ) {
        ENDPOINT = endpoint;
        CHANNEL = channel;
        owner = dao;
    }

    receive() external payable {}

    function changeOwner(address owner_) external onlyOwner {
        owner = owner_;
    }

    function isApproved(address operator) public view returns (bool) {
        return approvedOf[operator];
    }

    function setApproved(address operator, bool approve) public onlyOwner {
        approvedOf[operator] = approve;
        emit SetApproved(operator, approve);
    }

    function setDstPrice(uint256 chainId, uint128 dstPriceRatio, uint128 dstGasPriceInWei) external onlyApproved {
        priceOf[chainId] = DstPrice(dstPriceRatio, dstGasPriceInWei);
        emit SetDstPrice(chainId, dstPriceRatio, dstGasPriceInWei);
    }

    function setDstConfig(uint256 chainId, uint64 baseGas, uint64 gasPerByte) external onlyApproved {
        configOf[chainId] = DstConfig(baseGas, gasPerByte);
        emit SetDstConfig(chainId, baseGas, gasPerByte);
    }

    function withdraw(address to, uint256 amount) external onlyApproved {
        (bool success,) = to.call{value: amount}("");
        require(success, "!withdraw");
    }

    // params = [extraGas]
    function fee(uint256 toChainId, address, /*ua*/ uint256 size, bytes calldata params)
        public
        view
        returns (uint256)
    {
        uint256 extraGas = abi.decode(params, (uint256));
        DstPrice memory p = priceOf[toChainId];
        DstConfig memory c = configOf[toChainId];

        // remoteToken = dstGasPriceInWei * (baseGas + extraGas)
        uint256 remoteToken = p.dstGasPriceInWei * (c.baseGas + extraGas);
        // dstPriceRatio = dstPrice / localPrice * 10^10
        // sourceToken = RemoteToken * dstPriceRatio
        uint256 sourceToken = remoteToken * p.dstPriceRatio / (10 ** 10);
        uint256 payloadToken = c.gasPerByte * size * p.dstGasPriceInWei * p.dstPriceRatio / (10 ** 10);
        return sourceToken + payloadToken;
    }

    function assign(bytes32 msgHash, bytes calldata params) external payable {
        require(msg.sender == ENDPOINT, "!enpoint");
        emit Assigned(msgHash, msg.value, params);
    }

    function relay(Message calldata message, bytes calldata proof, uint256 gasLimit) external onlyApproved {
        IChannel(CHANNEL).recvMessage(message, proof, gasLimit);
    }
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

/// @dev User application custom configuration.
/// @param oracle Oracle contract address.
/// @param relayer Relayer contract address.
struct Config {
    address oracle;
    address relayer;
}

interface IUserConfig {
    /// @dev Fetch user application config.
    /// @notice If user application has not configured, then the default config is used.
    /// @param ua User application contract address.
    /// @return user application config.
    function getAppConfig(address ua) external view returns (Config memory);

    /// @notice Set user application config.
    /// @param oracle Oracle which user application choose.
    /// @param relayer Relayer which user application choose.
    function setAppConfig(address oracle, address relayer) external;

    function setDefaultConfig(address oracle, address relayer) external;
    function defaultConfig() external view returns (Config memory);
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

/// @dev The block of control information and data for comminicate
/// between user applications. Messages are the exchange medium
/// used by channels to send and receive data through cross-chain networks.
/// A message is sent from a source chain to a destination chain.
/// @param index The leaf index lives in channel's incremental mekle tree.
/// @param fromChainId The message source chain id.
/// @param from User application contract address which send the message.
/// @param toChainId The Message destination chain id.
/// @param to User application contract address which receive the message.
/// @param encoded The calldata which encoded by ABI Encoding.
struct Message {
    address channel;
    uint256 index;
    uint256 fromChainId;
    address from;
    uint256 toChainId;
    address to;
    bytes encoded; /*(abi.encodePacked(SELECTOR, PARAMS))*/
}

/// @dev Hash of the message.
function hash(Message memory message) pure returns (bytes32) {
    return keccak256(abi.encode(message));
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

interface IOracle {
    /// @notice Fetch oracle price to relay message root to the destination chain.
    /// @param toChainId The destination chain id.
    /// @param ua The user application which send the message.
    /// @return Oracle price in source native gas.
    function fee(uint256 toChainId, address ua) external view returns (uint256);

    /// @notice Assign the relay message root task to oracle maintainer.
    /// @param msgHash Hash of the message.
    function assign(bytes32 msgHash) external payable;

    /// @notice Fetch message root oracle.
    /// @param chainId The destination chain id.
    /// @return Message root in destination chain.
    function merkleRoot(uint256 chainId) external view returns (bytes32);
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "../Common.sol";

interface IChannel {
    function sendMessage(address from, uint256 toChainId, address to, bytes calldata encoded)
        external
        returns (bytes32);
    function recvMessage(Message calldata message, bytes calldata proof, uint256 gasLimit) external;
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

interface IRelayer {
    /// @notice Fetch relayer price to relay message to the destination chain.
    /// @param toChainId The destination chain id.
    /// @param ua The user application which send the message.
    /// @param size The size of message encoded payload.
    /// @param params General extensibility for relayer to custom functionality.
    /// @return Relayer price in source native gas.
    function fee(uint256 toChainId, address ua, uint256 size, bytes calldata params) external view returns (uint256);

    /// @notice Assign the relay message task to relayer maintainer.
    /// @param msgHash Hash of the message.
    /// @param params General extensibility for relayer to custom functionality.
    function assign(bytes32 msgHash, bytes calldata params) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract ReentrancyGuard {
    // send and receive nonreentrant lock
    uint8 internal constant _NOT_ENTERED = 1;
    uint8 internal constant _ENTERED = 2;
    uint8 internal _send_state = 1;
    uint8 internal _receive_state = 1;

    modifier sendNonReentrant() {
        require(_send_state == _NOT_ENTERED, "!send-reentrancy");
        _send_state = _ENTERED;
        _;
        _send_state = _NOT_ENTERED;
    }

    modifier recvNonReentrant() {
        require(_receive_state == _NOT_ENTERED, "!recv-reentrancy");
        _receive_state = _ENTERED;
        _;
        _receive_state = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

// Inspired: https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/util/ExcessivelySafeCall.sol

library ExcessivelySafeCall {
    uint256 internal constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata)
        internal
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly ("memory-safe") {
            _success :=
                call(
                    _gas, // gas
                    _target, // recipient
                    0, // ether value
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(address _target, uint256 _gas, uint16 _maxCopy, bytes memory _calldata)
        internal
        view
        returns (bool, bytes memory)
    {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly ("memory-safe") {
            _success :=
                staticcall(
                    _gas, // gas
                    _target, // recipient
                    add(_calldata, 0x20), // inloc
                    mload(_calldata), // inlen
                    0, // outloc
                    0 // outlen
                )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) { _toCopy := _maxCopy }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Swaps function selectors in encoded contract calls
    /// @dev Allows reuse of encoded calldata for functions with identical
    /// argument types but different names. It simply swaps out the first 4 bytes
    /// for the new selector. This function modifies memory in place, and should
    /// only be used with caution.
    /// @param _newSelector The new 4-byte selector
    /// @param _buf The encoded contract args
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly ("memory-safe") {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "../Common.sol";

interface IEndpoint {
    /// @dev Send a cross-chain message over the endpoint.
    /// @notice follow https://eips.ethereum.org/EIPS/eip-5750
    /// @param toChainId The Message destination chain id.
    /// @param to User application contract address which receive the message.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param params General extensibility for relayer to custom functionality.
    /// @return Return the hash of the message as message id.
    function send(uint256 toChainId, address to, bytes calldata encoded, bytes calldata params)
        external
        payable
        returns (bytes32);

    /// @notice Get a quote in source native gas, for the amount that send() requires to pay for message delivery.
    /// @param toChainId The Message destination chain id.
    //  @param to User application contract address which receive the message.
    /// @param encoded The calldata which encoded by ABI Encoding.
    /// @param params General extensibility for relayer to custom functionality.
    function fee(uint256 toChainId, address, /*to*/ bytes calldata encoded, bytes calldata params) external view;

    /// @dev Retry failed message.
    /// @notice Only message.to could clear this message.
    /// @param message Failed message info.
    function clearFailedMessage(Message calldata message) external;

    /// @dev Retry failed message.
    /// @param message Failed message info.
    /// @return dispatchResult Result of the message dispatch.
    function retryFailedMessage(Message calldata message) external returns (bool dispatchResult);

    function recv(Message calldata message, uint256 gasLimit) external returns (bool dispatchResult);
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

interface IVerifier {
    /// @notice Verify message proof
    /// @dev Message proof provided by relayer. Oracle should provide message root of
    ///      source chain, and verify the merkle proof of the message hash.
    /// @param fromChainId Source chain id.
    /// @param msgHash Hash of the message.
    /// @param proof Merkle proof of the message
    /// @return Result of the message verify.
    function verifyMessageProof(uint256 fromChainId, bytes32 msgHash, bytes calldata proof)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

// Inspired: https://github.com/nomad-xyz/monorepo/blob/main/packages/contracts-core/contracts/libs/Merkle.sol

/// @title IncrementalMerkleTree
/// @author Illusory Systems Inc.
/// @notice An incremental merkle tree modeled on the eth2 deposit contract.
library IncrementalMerkleTree {
    uint256 internal constant TREE_DEPTH = 32;
    uint256 internal constant MAX_LEAVES = 2 ** TREE_DEPTH - 1;

    /// @notice Struct representing incremental merkle tree. Contains current
    /// branch and the number of inserted leaves in the tree.
    struct Tree {
        bytes32[TREE_DEPTH] branch;
        uint256 count;
    }

    /// @notice Inserts `_node` into merkle tree
    /// @dev Reverts if tree is full
    /// @param _node Element to insert into tree
    function insert(Tree storage _tree, bytes32 _node) internal {
        require(_tree.count < MAX_LEAVES, "merkle tree full");

        _tree.count += 1;
        uint256 size = _tree.count;
        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            if ((size & 1) == 1) {
                _tree.branch[i] = _node;
                return;
            }
            _node = keccak256(abi.encodePacked(_tree.branch[i], _node));
            size /= 2;
        }
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    /// @notice Calculates and returns`_tree`'s current root given array of zero
    /// hashes
    /// @param _zeroes Array of zero hashes
    /// @return _current Calculated root of `_tree`
    function rootWithCtx(Tree storage _tree, bytes32[TREE_DEPTH] memory _zeroes)
        internal
        view
        returns (bytes32 _current)
    {
        uint256 _index = _tree.count;

        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            uint256 _ithBit = (_index >> i) & 0x01;
            bytes32 _next = _tree.branch[i];
            if (_ithBit == 1) {
                _current = keccak256(abi.encodePacked(_next, _current));
            } else {
                _current = keccak256(abi.encodePacked(_current, _zeroes[i]));
            }
        }
    }

    /// @notice Calculates and returns`_tree`'s current root
    function root(Tree storage _tree) internal view returns (bytes32) {
        return rootWithCtx(_tree, zeroHashes());
    }

    /// @notice Returns array of TREE_DEPTH zero hashes
    /// @return _zeroes Array of TREE_DEPTH zero hashes
    function zeroHashes() internal pure returns (bytes32[TREE_DEPTH] memory _zeroes) {
        _zeroes[0] = Z_0;
        _zeroes[1] = Z_1;
        _zeroes[2] = Z_2;
        _zeroes[3] = Z_3;
        _zeroes[4] = Z_4;
        _zeroes[5] = Z_5;
        _zeroes[6] = Z_6;
        _zeroes[7] = Z_7;
        _zeroes[8] = Z_8;
        _zeroes[9] = Z_9;
        _zeroes[10] = Z_10;
        _zeroes[11] = Z_11;
        _zeroes[12] = Z_12;
        _zeroes[13] = Z_13;
        _zeroes[14] = Z_14;
        _zeroes[15] = Z_15;
        _zeroes[16] = Z_16;
        _zeroes[17] = Z_17;
        _zeroes[18] = Z_18;
        _zeroes[19] = Z_19;
        _zeroes[20] = Z_20;
        _zeroes[21] = Z_21;
        _zeroes[22] = Z_22;
        _zeroes[23] = Z_23;
        _zeroes[24] = Z_24;
        _zeroes[25] = Z_25;
        _zeroes[26] = Z_26;
        _zeroes[27] = Z_27;
        _zeroes[28] = Z_28;
        _zeroes[29] = Z_29;
        _zeroes[30] = Z_30;
        _zeroes[31] = Z_31;
    }

    /// @notice Calculates and returns the merkle root for the given leaf
    /// `_item`, a merkle branch, and the index of `_item` in the tree.
    /// @param _item Merkle leaf
    /// @param _branch Merkle proof
    /// @param _index Index of `_item` in tree
    /// @return _current Calculated merkle root
    function branchRoot(bytes32 _item, bytes32[TREE_DEPTH] memory _branch, uint256 _index)
        internal
        pure
        returns (bytes32 _current)
    {
        _current = _item;

        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            uint256 _ithBit = (_index >> i) & 0x01;
            bytes32 _next = _branch[i];
            if (_ithBit == 1) {
                _current = keccak256(abi.encodePacked(_next, _current));
            } else {
                _current = keccak256(abi.encodePacked(_current, _next));
            }
        }
    }

    // keccak256 zero hashes
    bytes32 internal constant Z_0 = hex"0000000000000000000000000000000000000000000000000000000000000000";
    bytes32 internal constant Z_1 = hex"ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5";
    bytes32 internal constant Z_2 = hex"b4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30";
    bytes32 internal constant Z_3 = hex"21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85";
    bytes32 internal constant Z_4 = hex"e58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344";
    bytes32 internal constant Z_5 = hex"0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d";
    bytes32 internal constant Z_6 = hex"887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968";
    bytes32 internal constant Z_7 = hex"ffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83";
    bytes32 internal constant Z_8 = hex"9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af";
    bytes32 internal constant Z_9 = hex"cefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0";
    bytes32 internal constant Z_10 = hex"f9dc3e7fe016e050eff260334f18a5d4fe391d82092319f5964f2e2eb7c1c3a5";
    bytes32 internal constant Z_11 = hex"f8b13a49e282f609c317a833fb8d976d11517c571d1221a265d25af778ecf892";
    bytes32 internal constant Z_12 = hex"3490c6ceeb450aecdc82e28293031d10c7d73bf85e57bf041a97360aa2c5d99c";
    bytes32 internal constant Z_13 = hex"c1df82d9c4b87413eae2ef048f94b4d3554cea73d92b0f7af96e0271c691e2bb";
    bytes32 internal constant Z_14 = hex"5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc";
    bytes32 internal constant Z_15 = hex"da7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2";
    bytes32 internal constant Z_16 = hex"2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f";
    bytes32 internal constant Z_17 = hex"e1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a";
    bytes32 internal constant Z_18 = hex"5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0";
    bytes32 internal constant Z_19 = hex"b46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0";
    bytes32 internal constant Z_20 = hex"c65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2";
    bytes32 internal constant Z_21 = hex"f4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9";
    bytes32 internal constant Z_22 = hex"5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377";
    bytes32 internal constant Z_23 = hex"4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652";
    bytes32 internal constant Z_24 = hex"cdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef";
    bytes32 internal constant Z_25 = hex"0abf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d";
    bytes32 internal constant Z_26 = hex"b8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0";
    bytes32 internal constant Z_27 = hex"838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e";
    bytes32 internal constant Z_28 = hex"662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e";
    bytes32 internal constant Z_29 = hex"388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322";
    bytes32 internal constant Z_30 = hex"93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735";
    bytes32 internal constant Z_31 = hex"8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9";
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "./interfaces/IVerifier.sol";
import "./imt/IncrementalMerkleTree.sol";

abstract contract Verifier is IVerifier {
    /// @notice Message proof.
    /// @param messageIndex Leaf index of the message hash in incremental merkle tree.
    /// @param messageProof Merkle proof of the message hash.
    struct Proof {
        uint256 blockNumber;
        uint256 messageIndex;
        bytes32[32] messageProof;
    }

    /// @notice Fetch message root oracle.
    /// @param chainId The destination chain id.
    /// @param blockNumber The block number where the message root is located.
    /// @return Message root in destination chain.
    function merkleRoot(uint256 chainId, uint256 blockNumber) public view virtual returns (bytes32);

    /// @inheritdoc IVerifier
    function verifyMessageProof(uint256 fromChainId, bytes32 msgHash, bytes calldata proof)
        external
        view
        returns (bool)
    {
        // decode proof
        Proof memory p = abi.decode(proof, (Proof));

        // fetch message root in block number from chain
        bytes32 imtRootOracle = merkleRoot(fromChainId, p.blockNumber);
        // calculate the expected root based on the proof
        bytes32 imtRootProof = IncrementalMerkleTree.branchRoot(msgHash, p.messageProof, p.messageIndex);

        // check oracle's merkle root equal relayer's merkle root
        return imtRootOracle == imtRootProof;
    }
}

// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

interface IFeedOracle {
    function messageRoot() external view returns (bytes32);
}