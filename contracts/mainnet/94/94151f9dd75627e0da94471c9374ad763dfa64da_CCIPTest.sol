// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract CCIPTest {
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    string public constant URL = "https://api.yieldchain.io/ccip-test/{data}";

    function testCCIPRequest(
        bytes calldata response,
        bytes calldata extraData
    ) external view returns (bytes memory retValue) {
        if (bytes32(response) != bytes32(0)) {
            return bytes.concat(response, extraData);
        }

        string[] memory urls = new string[](1);
        urls[0] = URL;

        revert OffchainLookup(
            address(this),
            urls,
            extraData,
            CCIPTest.testCCIPRequest.selector,
            new bytes(0)
        );
    }

    string something = "sfasfsa";

    function testGas() public returns (uint256 posterFee) {
        for (uint256 i; i < 5; i++)
            something = string.concat(something, "pooo");

        (
            bool success,
            bytes memory res
        ) = 0x000000000000000000000000000000000000006C.staticcall(
                "getCurrentTxL1GasFees()"
            );

        posterFee = abi.decode(res, (uint256));
    }
}