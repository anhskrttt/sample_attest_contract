# nft-japan/NFT-JAPAN-CONTRACTS
## Getting Started

Download links:

SSH clone URL: ssh://172.16.10.49:22/DefaultCollection/NFT-JAPAN/_git/NFT-JAPAN-CONTRACT

HTTPS clone URL: http://172.16.10.49/DefaultCollection/NFT-JAPAN/_git/NFT-JAPAN-CONTRACT


These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

## Prerequisites
Install dependencies.

```
yarn install
```

Create .env file. Copy example content from .env.example file.


## Deployment
#### Deploy contract to local network
```
yarn deploy
```

#### Deploy contract to tomotestnet
Please double check if you deleted the code lines for testing purpose if you did add these lines.

```
yarn deploy:tomotestnet
```

#### Deploy contract to main net
**Important:** Please double check if you deleted the code lines for testing purpose if you did add these lines.

```
yarn deploy:tomomainnet
```

### Test
Copy this part into SotaToken.sol
Paste these code lines below the ``` function unpublishBatch() ```
```
    // ===================================================
    // For testing purpose only.
    // Please delete these view functions below when deploy to mainnet.

    function currentTokenIdCount() public view returns (uint256) {
        return _currentTokenId;
    }

    function creatorOfToken(uint256 _tokenId) public view returns (address) {
        return creators[_tokenId];
    }

    function publishSupplyOf(uint256 _tokenId) public view returns (uint256) {
        return publishSupplies[_tokenId];
    }

    function isFreeToken(uint256 _tokenId) public view returns (bool) {
        return isFree[_tokenId];
    }

    function isPublishedToken(uint256 _tokenId) public view returns (bool) {
        return isPublished[_tokenId];
    }

    function isCreator(address account) public view returns (bool) {
        return hasRole(CREATOR_ROLE, account);
    }

    // For testing purpose only.
    // Please delete these view functions above when deploy to mainnet.
    // ===================================================

```

First, start hardhat node.
```
yarn hardhat node
```
Then, start the test. Please double check if you pasted the line codes for testing purpose.
```
yarn hardhat test
```

## Resources

[OpenZeppelin](https://openzeppelin.com)
[UUPS Proxies](https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786)

## Expectation for future improvement
upgradeable-contract: [OpenZeppelin-UUPS](https://www.npmjs.com/package/@openzeppelin/contracts-upgradeable). Please take deployment-cost into consideration.