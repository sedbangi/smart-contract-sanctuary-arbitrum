// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Constants {
    error NetworkNotConfigured();

    struct External {
        address zeroExProxy;
        address stargateRouter;
        uint16 stargateChainId;
    }

    struct Config {
        uint256 defaultFeeBps;
        uint256 defaultSeedingPeriod;
        uint256[] stgDestChainIds;
    }

    struct System {
        address poolTemplate;
        address poolRegistry;
        address poolFactory;
        address lens;
        address swapper;
        address zap;
        address tokenKeeper;
        address stargateReceiver;
        address testToken;
    }

    struct Values {
        External ext;
        Config cfg;
        System sys;
        string deployerPrivateKeyEnvVar;
    }

    function get(uint256 chainId) external pure returns (Values memory) {
        if (chainId == 5) {
            return getGoerli();
        } else if (chainId == 421_613) {
            return getArbGoerli();
        } else if (chainId == 42_161) {
            return getArb();
        } else if (chainId == 10) {
            return getOpti();
        } else if (chainId == 1) {
            return getMainnet();
        } else {
            revert NetworkNotConfigured();
        }
    }

    function getMainnet() private pure returns (Values memory) {
        uint256[] memory stgDestChainIds = new uint256[](2);
        stgDestChainIds[0] = 42_161; //Arbitrum
        stgDestChainIds[1] = 10; //Optimism

        return Values({
            ext: External({
                zeroExProxy: 0xDef1C0ded9bec7F1a1670819833240f027b25EfF,
                stargateRouter: 0xeCc19E177d24551aA7ed6Bc6FE566eCa726CC8a9,
                stargateChainId: 101
            }),
            cfg: Config({ defaultFeeBps: 300, defaultSeedingPeriod: 1 weeks, stgDestChainIds: stgDestChainIds }),
            sys: System({
                poolTemplate: 0x8780CDEf8Ab37620552c7df390fE23e56084ee4a,
                poolRegistry: 0x16e8E98Ec0d7eA6A4b4037093D79b7D13eb6AECE,
                poolFactory: 0xabC598178C50a3ABb4CAa7e233D7c08C0538caF8,
                lens: 0x62a0889Dc3D7551bF427339071FAeE1556B32000,
                swapper: 0xf532ebb02A26A47C6B913B61a2A6316c0E4E3678,
                zap: 0xe88D82a432708Ad0D2e0893498B92fdef4679369,
                tokenKeeper: 0x4C6bdef904082b33839Ae1B88BCFe90AA3002151,
                stargateReceiver: 0x419231984126D97a9b9A3Bf06A24e1C2c9166826,
                testToken: 0xD5D7114E16DCD2adF0b3246A90B50C598c3944B4
            }),
            deployerPrivateKeyEnvVar: "DEPLOYER_PRIVATE_KEY_MAINNET"
        });
    }

    function getOpti() private pure returns (Values memory) {
        uint256[] memory stgDestChainIds = new uint256[](2);
        stgDestChainIds[0] = 42_161; //Arbitrum
        stgDestChainIds[1] = 1; //Mainnet

        return Values({
            ext: External({
                zeroExProxy: 0xDEF1ABE32c034e558Cdd535791643C58a13aCC10,
                stargateRouter: 0xeCc19E177d24551aA7ed6Bc6FE566eCa726CC8a9,
                stargateChainId: 111
            }),
            cfg: Config({ defaultFeeBps: 300, defaultSeedingPeriod: 1 weeks, stgDestChainIds: stgDestChainIds }),
            sys: System({
                poolTemplate: 0x8780CDEf8Ab37620552c7df390fE23e56084ee4a,
                poolRegistry: 0x16e8E98Ec0d7eA6A4b4037093D79b7D13eb6AECE,
                poolFactory: 0xabC598178C50a3ABb4CAa7e233D7c08C0538caF8,
                lens: 0x62a0889Dc3D7551bF427339071FAeE1556B32000,
                swapper: 0xf532ebb02A26A47C6B913B61a2A6316c0E4E3678,
                zap: 0x8dc5fF93ceA8B30B70Ffe4d360aC94987cc84504,
                tokenKeeper: 0x4C6bdef904082b33839Ae1B88BCFe90AA3002151,
                stargateReceiver: 0x7e2e1C18FC2f213950679b5784695555da9412B6,
                testToken: 0x67B52D17c50d15849a6755D22954dED2372464d3
            }),
            deployerPrivateKeyEnvVar: "DEPLOYER_PRIVATE_KEY_MAINNET"
        });
    }

    function getArb() private pure returns (Values memory) {
        uint256[] memory stgDestChainIds = new uint256[](2);
        stgDestChainIds[0] = 10; //Optimism
        stgDestChainIds[1] = 1; //Mainnet

        return Values({
            ext: External({
                zeroExProxy: 0xDef1C0ded9bec7F1a1670819833240f027b25EfF,
                stargateRouter: 0xeCc19E177d24551aA7ed6Bc6FE566eCa726CC8a9,
                stargateChainId: 110
            }),
            cfg: Config({ defaultFeeBps: 300, defaultSeedingPeriod: 1 weeks, stgDestChainIds: stgDestChainIds }),
            sys: System({
                poolTemplate: 0x8780CDEf8Ab37620552c7df390fE23e56084ee4a,
                poolRegistry: 0x16e8E98Ec0d7eA6A4b4037093D79b7D13eb6AECE,
                poolFactory: 0xabC598178C50a3ABb4CAa7e233D7c08C0538caF8,
                lens: 0x62a0889Dc3D7551bF427339071FAeE1556B32000,
                swapper: 0xf532ebb02A26A47C6B913B61a2A6316c0E4E3678,
                zap: 0x7512299A6291e04B6ae6be38C83f35A346a91fa8,
                tokenKeeper: 0x4C6bdef904082b33839Ae1B88BCFe90AA3002151,
                stargateReceiver: 0xCCeF19a596bD4435856423983D20De962b0A9953,
                testToken: 0x67B52D17c50d15849a6755D22954dED2372464d3
            }),
            deployerPrivateKeyEnvVar: "DEPLOYER_PRIVATE_KEY_MAINNET"
        });
    }

    function getGoerli() private pure returns (Values memory) {
        uint256[] memory stgDestChainIds = new uint256[](1);
        stgDestChainIds[0] = 421_613; //Arb-Goerli

        return Values({
            ext: External({
                zeroExProxy: 0xF91bB752490473B8342a3E964E855b9f9a2A668e,
                stargateRouter: 0x7612aE2a34E5A363E137De748801FB4c86499152,
                stargateChainId: 10_121
            }),
            cfg: Config({ defaultFeeBps: 500, defaultSeedingPeriod: 1 weeks, stgDestChainIds: stgDestChainIds }),
            sys: System({
                poolTemplate: 0x6De2e15204fd33D735Dc1EBE87b6c5E44CE2aF8d,
                poolRegistry: 0xd5f2B88D33A7287E55a08df9Ac6925B1929C4B14,
                poolFactory: 0x9b9bF8A47Ed98dA242d3231fb19e7202c02dD7A9,
                lens: 0xdE149969AF0c9e103035eeE5C3d43A1f5a89274E,
                swapper: 0x866D21bd9f156CcA13bb7Ee981756e8417c0a8b3,
                zap: 0x5F02f58D1DEDe4F89b7E13a9aF324316A0a51801,
                tokenKeeper: 0xe5F482BC6682B9514F96Bc551CF0707AcD3159A9,
                stargateReceiver: 0x21cd4A99af15F7433b2673094729d225f0FCDAa3,
                testToken: address(0)
            }),
            deployerPrivateKeyEnvVar: "DEPLOYER_PRIVATE_KEY"
        });
    }

    function getArbGoerli() private pure returns (Values memory) {
        uint256[] memory stgDestChainIds = new uint256[](1);
        stgDestChainIds[0] = 5; //Goerli

        return Values({
            ext: External({
                zeroExProxy: address(1),
                stargateRouter: 0xb850873f4c993Ac2405A1AdD71F6ca5D4d4d6b4f,
                stargateChainId: 10_143
            }),
            cfg: Config({ defaultFeeBps: 500, defaultSeedingPeriod: 1 weeks, stgDestChainIds: stgDestChainIds }),
            sys: System({
                poolTemplate: 0x4CE2D9dF831dC1EB1EF7b22109e84D1507055106,
                poolRegistry: 0xC4dd5cdc80f875A28981BdA7F2D5Dbd162d29510,
                poolFactory: 0xeF78712aeF82452F6ce515160496D733b7031840,
                lens: 0x52226824F5CAE9de64bd6f837F7e1276c6696950,
                swapper: 0xf55cA63D5DC9e7aB14c4645aD1F25DBE41f551E4,
                zap: 0x89165dC5e2d96d78574C1cC2C0a92B1b13B75913,
                tokenKeeper: 0x47441B3DAda946D2dC40E0a2ADaA8Ed197C6Db98,
                stargateReceiver: 0x7102BeAF394440Fd4421Eec52dF06b685f8bB8CD,
                testToken: address(0)
            }),
            deployerPrivateKeyEnvVar: "DEPLOYER_PRIVATE_KEY"
        });
    }
}