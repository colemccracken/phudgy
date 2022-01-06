// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract PudgyPenguins {
  function ownerOf(uint256 tokenId) public view returns (address) {}
}

contract PhudgyPhenguins is ERC721Enumerable, Ownable, ERC721Burnable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdTracker;

  uint256 public constant MAX_ELEMENTS = 8888;
  uint256 public constant PRICE = 0.0169 ether;
  uint256 public constant MAX_BY_MINT = 20;

  PudgyPenguins pudgyContract;
  string public baseTokenURI;
  bool public publicMinting = false;
  bool public pudgyMinting = true;

  event CreatePhenguin(uint256 indexed id);

  constructor(PudgyPenguins pudgyContractAddr, string memory baseURI)
    ERC721("PhudgyPhenguins", "PPG")
  {
    setBaseURI(baseURI);
    pudgyContract = pudgyContractAddr;
  }

  modifier publicMintingMod() {
    require(publicMinting);
    _;
  }

  modifier pudgyMintingMod() {
    require(pudgyMinting);
    _;
  }

  function totalMint() external view returns (uint256) {
    return totalSupply();
  }

  function publicMint(uint256 _count) external payable publicMintingMod {
    uint256 total = totalSupply();
    require(total + _count <= MAX_ELEMENTS, "Max limit");
    require(total <= MAX_ELEMENTS, "Sale end");
    require(_count <= MAX_BY_MINT, "Exceeds number");
    require(msg.value >= price(_count), "Value below price");

    uint256 i = 0;
    while (i < _count && i < MAX_ELEMENTS) {
      uint256 currentIdx = _tokenIdTracker.current();
      if (_exists(currentIdx)) {
        _tokenIdTracker.increment();
      } else {
        i++;
        _mintAnElement(msg.sender, currentIdx);
      }
    }
  }

  function pudgyMint(uint256 tokenId) external pudgyMintingMod {
    require(pudgyContract.ownerOf(tokenId) == msg.sender);
    _mintAnElement(msg.sender, tokenId);
  }

  function _mintAnElement(address _to, uint256 id) private {
    _safeMint(_to, id);
    emit CreatePhenguin(id);
  }

  function price(uint256 _count) public pure returns (uint256) {
    return PRICE * _count;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    baseTokenURI = baseURI;
  }

  function setPublicMinting(bool val) public onlyOwner {
    publicMinting = val;
  }

  function setPudgyMinting(bool val) public onlyOwner {
    pudgyMinting = val;
  }

  function walletOfOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensId;
  }

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    (bool success, ) = owner().call{ value: balance }("");
    require(success, "Withdraw failed.");
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
