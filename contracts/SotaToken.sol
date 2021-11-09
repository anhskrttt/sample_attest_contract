// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./MyTRC21MintableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SotaToken is
    Initializable,
    MyTRC21MintableUpgradeable,
    ERC1155Upgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155PausableUpgradeable,
    UUPSUpgradeable
{
    using ECDSAUpgradeable for bytes32;

    // Constant variables.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    // State variables.

    // _currentTokenId is always go beyond the "real" current token Id.
    // E.g: initial tokenId = 1 (Start minting token at position 1, position 0 empty).
    //      initial _currentTokenId = 2
    uint256 private _currentTokenId;

    // Change to private when deploy to mainnet.
    // tokenId (index of token in "array") -> episodeId (in string) of that Id.
    mapping(uint256 => string) public episodeIds;
    // tokenId -> address of creator (who created that token).
    mapping(uint256 => address) public creators;
    // tokenId -> its total supply (initially set by creator -> unchanged).
    mapping(uint256 => uint256) public totalSupplies;
    // tokenId -> its published amount (included its sold amount).
    // if token is free ep -> publishSupplies = 0. We're not tracking this value of free ep.
    mapping(uint256 => uint256) public publishSupplies;
    // tokenId -> is it free?
    mapping(uint256 => bool) public isFree;
    mapping(uint256 => bool) public isPublished;

    // Events.
    event Publish(uint256 indexed id, uint256 indexed amount);
    //event PublishBatch(uint256[] indexed ids, uint256[] indexed amounts);
    event Unpublish(uint256 indexed id);

    function initialize(string memory name, string memory symbol) public initializer {
        __TRC21_init(name, symbol, 18, 1000000000 * (10**18), 0);
        __ERC1155_init("");
        __AccessControlEnumerable_init();
        __ERC1155Burnable_init();
        __ERC1155Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _currentTokenId = 1;
    }

    modifier onlyRoleCanPublish(uint256 tokenId) {
        require(
            (hasRole(CREATOR_ROLE, _msgSender()) &&
                creators[tokenId] == _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "SotaToken: restricted access"
        );
        _;
    }

    modifier whenPublish(uint256 tokenId) {
        require(isPublished[tokenId], "SotaToken: not publish");
        _;
    }

    modifier whenUnpublish(uint256 tokenId) {
        require(!isPublished[tokenId], "SotaToken: published");
        _;
    }

    /// @dev Add an account to the creator role. Restricted to admins.
    function addCreator(address _creatorAddress) public {
        grantRole(CREATOR_ROLE, _creatorAddress);
    }

    /// @dev Remove an account from the creator role. Restricted to admins.
    function removeCreator(address _creatorAddress) public {
        revokeRole(CREATOR_ROLE, _creatorAddress);
    }

    // Creator can only mint tokens to his/her own wallet.
    function mint(
        address _adminAddress,
        string memory _episodeId,
        bool _isFree,
        uint256 _totalSupply,
        bytes memory data
    ) public onlyRole(CREATOR_ROLE) {
        address creatorAddress = _msgSender();
        // Check current tokenId is available for minting (Empty token).
        // Avoid existed token.
        // Avoid override tokenId.
        require(
            creators[_currentTokenId] == address(0),
            "SotaToken: tokenId already exists"
        );

        // Can remove this for optimization.
        require(_totalSupply != 0, "SotaToken: Mint with amount 0");

        if (_isFree) {
            isFree[_currentTokenId] = true;
            _totalSupply = 1;
        }

        _mint(creatorAddress, _currentTokenId, _totalSupply, data);
        setApprovalForAll(_adminAddress, true);

        episodeIds[_currentTokenId] = _episodeId;
        totalSupplies[_currentTokenId] = _totalSupply;
        // Mapping nft-id corresponding to its owner/creator.
        creators[_currentTokenId] = creatorAddress;
        _incrementTokenId(1);
    }

    // Available to publish ep with amount = 0
    // -> only when author has none of this tokenID.
    function publish(uint256 _tokenId, uint256 _amount)
        public
        onlyRoleCanPublish(_tokenId)
        whenUnpublish(_tokenId)
    {
        require(_tokenId != 0, "SotaToken: publish token at index zero");

        if (isFree[_tokenId]) {
            _amount = 0;
        } else {
            // Take this condition into consideration.
            // Remove this for optimization if needed.
            if (balanceOf(creators[_tokenId], _tokenId) != 0) {
                require(_amount != 0, "SotaToken: Publish with amount = 0");
            }

            require(
                _amount <= balanceOf(_msgSender(), _tokenId),
                "SotaToken: publish token with inappropriate"
            );

            publishSupplies[_tokenId] += _amount;
        }
        isPublished[_tokenId] = true;
        emit Publish(_tokenId, _amount);
    }
    function unpublish(uint256 _tokenId)
        public
        onlyRoleCanPublish(_tokenId)
        whenPublish(_tokenId)
    {
        if (!isFree[_tokenId]) {
            // Set amount of published token to token that is sold.
            publishSupplies[_tokenId] = _getSoldAmountOf(_tokenId);
        }
        isPublished[_tokenId] = false;
        emit Unpublish(_tokenId);
    }

    // Please paste code for testing purpose here.

    // ===================================================
    // For testing purpose only.
    // Please delete these view functions below when deploy to mainnet.

    function isPublishedToken(uint256 _tokenId) public view returns (bool) {
        return isPublished[_tokenId];
    }

    // For testing purpose only.
    // Please delete these view functions above when deploy to mainnet.
    // ===================================================

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override onlyRole(DEFAULT_ADMIN_ROLE){
        if (isFree[id]) {
            value = 1;
        }
        super.burn(account, id, value);
        totalSupplies[id] -= value;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "SotaToken: must have pauser role to pause"
        );
        _pause();
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
        override(ERC1155Upgradeable, ERC1155PausableUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        // Detect only for creator's transaction.
        // Avoid minting and burning.
        // address(0): zero address.
        if (hasRole(CREATOR_ROLE, from) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 tokenId = ids[i];
                uint256 amount = amounts[i];
                require(
                    amount != 0,
                    "SotaToken: can not transfer with amount equals to zero"
                );

                // Detect only for items on sale.
                if (!isFree[tokenId]) {
                    require(
                        _getSoldAmountOf(tokenId) + amounts[i] <=
                            publishSupplies[tokenId],
                        "SotaToken: remaining amount not enough or token unpublished"
                    );
                }
            }
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Do something here.
    }

    // Private methods.
    function _incrementTokenId(uint256 _amount) private {
        _currentTokenId = _currentTokenId + _amount;
    }

    function _getSoldAmountOf(uint256 _tokenId) private view returns (uint256) {
        return (totalSupplies[_tokenId] -
            balanceOf(creators[_tokenId], _tokenId));
    }
}
