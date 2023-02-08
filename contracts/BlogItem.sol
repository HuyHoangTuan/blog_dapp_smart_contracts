pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlogItem is ERC721, ERC721URIStorage, Ownable
{
     using Counters for Counters.Counter;
     Counters.Counter private _tokenIdCounter;
     
     uint256 private _fees;

     constructor(
          string memory name,
          string memory symbol,
          uint256 fees
     ) ERC721(name, symbol)
     {
          _fees = fees;
     }

     struct node
     {
          uint256 parent;
          bool isExisted;
     }
     mapping(uint256 => node) graph;

     struct mappingUriData
     {
          uint256 tokenId;
          bool isExisted;
     }
     mapping(string => mappingUriData) private uriMapping;

     mapping(address => uint256[]) private listTokenIdOf;
     
     struct medalStruct
     {
          uint256 num;
          bool isExisted;
     }
     
     mapping(uint256 => medalStruct) private medalMapping;

     uint256[] private publisedTokenId;

     function getFees() public view returns(uint256)
     {
          return _fees;
     }

     // only call when a new token was created
     function makeNode(uint256 tokenId)
          internal
     {
          graph[tokenId] = node({isExisted: true, parent: tokenId});
     }

     function findParent(uint256 nodeId)
          internal
          returns(uint256)
     {
          if(graph[nodeId].parent == nodeId) return nodeId;
          graph[nodeId].parent = findParent(graph[nodeId].parent);
          return graph[nodeId].parent;
     }

     function unionOldNodeToNewNode(uint256 oldNodeId, uint256 newNodeId)
          internal
          returns(bool)
     {
          uint256 u = findParent(oldNodeId);
          uint256 v = findParent(newNodeId);

          if(u == v) return false;
          
          graph[u].parent = v;
          return true;
     }

     function mintToken(address user, string memory uri)
          internal
          returns(uint256)
     {
          // mint nft
          uint256 tokenId = _tokenIdCounter.current();
          _tokenIdCounter.increment();
          _safeMint(user, tokenId);
          _setTokenURI(tokenId, uri);

          uriMapping[uri] = mappingUriData({tokenId: tokenId, isExisted: true});
          medalMapping[tokenId] = medalStruct({num: 0, isExisted: true}); 

          makeNode(tokenId);

          return tokenId;
     }
     

     function publicBlog(string memory uri)
          public
          payable
          returns(uint256)
     {
          require(isUriExisted(uri) == false, "URI is existed!");
          require(msg.value >= _fees, "Not enough balance! ");
          payable(owner()).transfer(_fees);
          
          // mint nft
          uint256 newTokenId = mintToken(msg.sender, uri);
          listTokenIdOf[msg.sender].push(newTokenId);
          publisedTokenId.push(newTokenId);

          uint256 contractBalance = address(this).balance;
          if(contractBalance > 0)
          {
               payable(msg.sender).transfer(address(this).balance); 
          }
          return newTokenId;
               
     }

     function editBlog(string memory old_uri, string memory new_uri)
          public
          payable
          returns(uint256)
     {
          uint256 oldTokenId = getTokenIdOfUri(old_uri);
          require(ownerOf(oldTokenId) == msg.sender, "You are not the owner!");
          require(isUriExisted(new_uri) == false, "URI is existed!");
          require(msg.value >= _fees, "Not enough balance!");
          payable(owner()).transfer(_fees);

          uint256 newTokenId = mintToken(ownerOf(oldTokenId), new_uri);

          bool union = unionOldNodeToNewNode(oldTokenId, newTokenId);
          require(union == true, "state is existed");
          medalMapping[newTokenId].num = medalMapping[oldTokenId].num;
          
          uint256 contractBalance = address(this).balance;
          if(contractBalance > 0)
          {
               payable(msg.sender).transfer(address(this).balance); 
          }
          return newTokenId;
     }

     function giveMedalToABlog(string memory old_uri)
          public
          payable
          returns(uint256)
     {
          uint256 oldTokenId = getTokenIdOfUri(old_uri);
          require(isUriExisted(old_uri) == true, "uri is not existed!");
          require(medalMapping[oldTokenId].isExisted == true, "medal is not existed");
          require(ownerOf(oldTokenId) != msg.sender, "You can not give medal to your own medal!");
          require(msg.value >= _fees, "Not enough balance!");
          uint256 parentToken = findParent(oldTokenId);
          require(parentToken == oldTokenId, "The blog was edited!");
          payable(ownerOf(oldTokenId)).transfer(msg.value);
          
          uint256 medal = ++medalMapping[parentToken].num;

          return medal;
     }

     function getTokenIdOfUri(string memory uri)
          public
          returns(uint256)
     {
          require(uriMapping[uri].isExisted == true, "Uri is not added!");
          return findParent(uriMapping[uri].tokenId);
     }

     function getListTokenIdOfAddress(address user)
          public
          returns(uint256[] memory)
     {
          uint256 len = listTokenIdOf[user].length;
          uint256[] memory output = new uint256[](len);
          for(uint256 i = 0; i < len; i++)
          {
               uint256 tokenId = listTokenIdOf[user][i];
               output[i] = findParent(tokenId);
          }
          return output;
     }

     function getListUriOfAddress(address user)
          public
          returns(string[] memory)
     {
          uint256[] memory listTokenId = getListTokenIdOfAddress(user);
          uint256 len = listTokenId.length;
          string[] memory output = new string[](len);
          for(uint256 i = 0 ; i < len; i++ )
          {
               uint256 tokenId = listTokenId[i];
               tokenId = findParent(tokenId);
               output[i] = tokenURI(tokenId);
          }

          return output;
     }

     function getAllPublishedUri()
          public
          returns(string[] memory)
     {
          uint256 len = publisedTokenId.length;
          string[] memory output = new string[](len);
          for(uint256 i = 0 ; i < len; i++)
          {
               uint256 tokenId = publisedTokenId[i];
               tokenId = findParent(tokenId);
               output[i] = tokenURI(tokenId);
          }

          return output;
     }

     function getMedalOfUri(string memory uri)
          public
          returns(uint256)
     {
          uint256 tokenId = getTokenIdOfUri(uri);
          require(medalMapping[tokenId].isExisted == true, "medal mapping is not existed!");
          return medalMapping[tokenId].num;
     }

     function isUriExisted(string memory uri)
          internal
          view
          returns(bool)
     {
          return uriMapping[uri].isExisted;
     }

     function _burn(uint256 tokenId)
          internal
          override(ERC721, ERC721URIStorage)
     {
          super._burn(tokenId);
     }

     function tokenURI(uint256 tokenId)
          public
          view
          override(ERC721, ERC721URIStorage)
          returns(string memory)
     {
          return super.tokenURI(tokenId);
     }


}