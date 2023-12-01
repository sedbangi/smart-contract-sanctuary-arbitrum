// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
/******************************************************************************\
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { ICegaEntryInterfaces } from "./interfaces/ICegaEntryInterfaces.sol";
import { IERC165 } from "./IERC165.sol";
import { CegaEntryLib } from "./lib/CegaEntryLib.sol";

// The EIP-2535 Diamond standard requires these functions.

contract CegaEntryInterfaces is ICegaEntryInterfaces, IERC165 {
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    // Facet == Implementtion

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Implementation
    function facets()
        external
        view
        override
        returns (Implementation[] memory facets_)
    {
        CegaEntryLib.ProxyStorage storage ds = CegaEntryLib.proxyStorage();
        uint256 numFacets = ds.implementationAddresses.length;
        facets_ = new Implementation[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.implementationAddresses[i];
            facets_[i].implAddress = facetAddress_;
            facets_[i].functionSelectors = ds
                .implementationFunctionSelectors[facetAddress_]
                .functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(
        address _facet
    ) external view override returns (bytes4[] memory facetFunctionSelectors_) {
        CegaEntryLib.ProxyStorage storage ds = CegaEntryLib.proxyStorage();
        facetFunctionSelectors_ = ds
            .implementationFunctionSelectors[_facet]
            .functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        CegaEntryLib.ProxyStorage storage ds = CegaEntryLib.proxyStorage();
        facetAddresses_ = ds.implementationAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(
        bytes4 _functionSelector
    ) external view override returns (address facetAddress_) {
        CegaEntryLib.ProxyStorage storage ds = CegaEntryLib.proxyStorage();
        facetAddress_ = ds
            .selectorToImplAndPosition[_functionSelector]
            .implAddress;
    }

    // This implements ERC-165.
    function supportsInterface(
        bytes4 _interfaceId
    ) external view override returns (bool) {
        CegaEntryLib.ProxyStorage storage ds = CegaEntryLib.proxyStorage();

        return (type(ICegaEntryInterfaces).interfaceId == _interfaceId ||
            ds.supportedInterfaces[_interfaceId]);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.10;

/******************************************************************************\
* EIP-2535: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface ICegaEntry {
    enum ProxyImplementationAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct ProxyImplementation {
        address implAddress;
        ProxyImplementationAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _implementationParams Contains the implementation addresses and function selectors
    /// @param _init The address of the contract or implementation to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        ProxyImplementation[] calldata _implementationParams,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(
        ProxyImplementation[] _diamondCut,
        address _init,
        bytes _calldata
    );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/******************************************************************************\
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// interfaces that are compatible with Diamond proxy loupe functions
interface ICegaEntryInterfaces {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Implementation {
        address implAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Implementation
    function facets() external view returns (Implementation[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.10;

/******************************************************************************\
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { ICegaEntry } from "../interfaces/ICegaEntry.sol";

library CegaEntryLib {
    bytes32 constant PROXY_STORAGE_POSITION =
        bytes32(uint256(keccak256("cega.proxy.implementation.storage")) - 1);

    struct ImplementationAddressAndPosition {
        address implAddress;
        uint96 functionSelectorPosition; // position in implementationFunctionSelectors.functionSelectors array
    }

    struct ImplementationFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 implementationAddressPosition; // position of implAddress in implementationAddresses array
    }

    struct ProxyStorage {
        // maps function selector to the implementation address and
        // the position of the selector in the implementationFunctionSelectors.selectors array
        mapping(bytes4 => ImplementationAddressAndPosition) selectorToImplAndPosition;
        // maps implementation addresses to function selectors
        mapping(address => ImplementationFunctionSelectors) implementationFunctionSelectors;
        // implementation addresses
        address[] implementationAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function proxyStorage() internal pure returns (ProxyStorage storage ds) {
        bytes32 position = PROXY_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        ProxyStorage storage ds = proxyStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = proxyStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == proxyStorage().contractOwner,
            "CegaEntry: Must be contract owner"
        );
    }

    event DiamondCut(
        ICegaEntry.ProxyImplementation[] _implementationData,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function updateImplementation(
        ICegaEntry.ProxyImplementation[] memory _implementationData,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 implIndex;
            implIndex < _implementationData.length;
            implIndex++
        ) {
            ICegaEntry.ProxyImplementationAction action = _implementationData[
                implIndex
            ].action;
            if (action == ICegaEntry.ProxyImplementationAction.Add) {
                addFunctions(
                    _implementationData[implIndex].implAddress,
                    _implementationData[implIndex].functionSelectors
                );
            } else if (action == ICegaEntry.ProxyImplementationAction.Replace) {
                replaceFunctions(
                    _implementationData[implIndex].implAddress,
                    _implementationData[implIndex].functionSelectors
                );
            } else if (action == ICegaEntry.ProxyImplementationAction.Remove) {
                removeFunctions(
                    _implementationData[implIndex].implAddress,
                    _implementationData[implIndex].functionSelectors
                );
            } else {
                revert("CegaEntry: Incorrect ProxyImplementationAction");
            }
        }
        emit DiamondCut(_implementationData, _init, _calldata);
        initializeImplementation(_init, _calldata);
    }

    function addFunctions(
        address _implementationAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "CegaEntry: No selectors in implementation to cut"
        );
        ProxyStorage storage ds = proxyStorage();
        require(
            _implementationAddress != address(0),
            "CegaEntry: Add implementation can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds
                .implementationFunctionSelectors[_implementationAddress]
                .functionSelectors
                .length
        );
        // add new implementation address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _implementationAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldImplementationAddress = ds
                .selectorToImplAndPosition[selector]
                .implAddress;
            require(
                oldImplementationAddress == address(0),
                "CegaEntry: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _implementationAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _implementationAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "CegaEntry: No selectors in implementation to cut"
        );
        ProxyStorage storage ds = proxyStorage();
        require(
            _implementationAddress != address(0),
            "CegaEntry: Replace implementation can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds
                .implementationFunctionSelectors[_implementationAddress]
                .functionSelectors
                .length
        );
        // add new implementation address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _implementationAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldImplementationAddress = ds
                .selectorToImplAndPosition[selector]
                .implAddress;
            require(
                oldImplementationAddress != _implementationAddress,
                "CegaEntry: Can't replace function with same function"
            );
            removeFunction(ds, oldImplementationAddress, selector);
            addFunction(ds, selector, selectorPosition, _implementationAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _implementationAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "CegaEntry: No selectors in implementation to cut"
        );
        ProxyStorage storage ds = proxyStorage();
        // if function does not exist then do nothing and return
        require(
            _implementationAddress == address(0),
            "CegaEntry: Remove implementation address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldImplementationAddress = ds
                .selectorToImplAndPosition[selector]
                .implAddress;
            removeFunction(ds, oldImplementationAddress, selector);
        }
    }

    function addFacet(
        ProxyStorage storage ds,
        address _implementationAddress
    ) internal {
        enforceHasContractCode(
            _implementationAddress,
            "CegaEntry: New implementation has no code"
        );
        ds
            .implementationFunctionSelectors[_implementationAddress]
            .implementationAddressPosition = ds.implementationAddresses.length;
        ds.implementationAddresses.push(_implementationAddress);
    }

    function addFunction(
        ProxyStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _implementationAddress
    ) internal {
        ds
            .selectorToImplAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds
            .implementationFunctionSelectors[_implementationAddress]
            .functionSelectors
            .push(_selector);
        ds
            .selectorToImplAndPosition[_selector]
            .implAddress = _implementationAddress;
    }

    function removeFunction(
        ProxyStorage storage ds,
        address _implementationAddress,
        bytes4 _selector
    ) internal {
        require(
            _implementationAddress != address(0),
            "CegaEntry: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a cegaEntry
        require(
            _implementationAddress != address(this),
            "CegaEntry: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToImplAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .implementationFunctionSelectors[_implementationAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .implementationFunctionSelectors[_implementationAddress]
                .functionSelectors[lastSelectorPosition];
            ds
                .implementationFunctionSelectors[_implementationAddress]
                .functionSelectors[selectorPosition] = lastSelector;
            ds
                .selectorToImplAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds
            .implementationFunctionSelectors[_implementationAddress]
            .functionSelectors
            .pop();
        delete ds.selectorToImplAndPosition[_selector];

        // if no more selectors for implementation address then delete the implementation address
        if (lastSelectorPosition == 0) {
            // replace implementation address with last implementation address and delete last implementation address
            uint256 lastImplementationAddressPosition = ds
                .implementationAddresses
                .length - 1;
            uint256 implementationAddressPosition = ds
                .implementationFunctionSelectors[_implementationAddress]
                .implementationAddressPosition;
            if (
                implementationAddressPosition !=
                lastImplementationAddressPosition
            ) {
                address lastImplementationAddress = ds.implementationAddresses[
                    lastImplementationAddressPosition
                ];
                ds.implementationAddresses[
                    implementationAddressPosition
                ] = lastImplementationAddress;
                ds
                    .implementationFunctionSelectors[lastImplementationAddress]
                    .implementationAddressPosition = implementationAddressPosition;
            }
            ds.implementationAddresses.pop();
            delete ds
                .implementationFunctionSelectors[_implementationAddress]
                .implementationAddressPosition;
        }
    }

    function initializeImplementation(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "CegaEntry: _init is address(0) but _calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "CegaEntry: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "CegaEntry: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    assembly {
                        revert(add(error, 0x20), mload(error))
                    }
                } else {
                    revert("CegaEntry: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        require(_contract.code.length > 0, _errorMessage);
    }
}