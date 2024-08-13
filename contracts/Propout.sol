// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// contract PropoutV1 is Initializable {
contract PropoutV1 {
    uint256 public propertyIndex;

    struct Property {
        uint256 propertyId;
        address owner;
        uint256 price;
        string propertyTitle;
        string[] images; // Array of image URLs or IPFS hashes
        string description;
        string propertyAddress;
        string propertyType;
        uint256 propertySpec;
        uint256 square;
        string city;
        string country;
        string listType;
        uint256 ownerId;
        bool isListed;
    }

    struct PropertyData {
        uint256 price;
        string propertyTitle;
        string[] images;
        string propertyAddress;
        string description;
        string propertyType;
        uint256 propertySpec;
        uint256 square;
        string city;
        string country;
        string listType;
    }

    struct PropertyDetails {
        uint256 propertyId;
        address owner;
        uint256 price;
        string propertyTitle;
        string[] images;
        string description;
        string propertyAddress;
        string propertyType;
        uint256 propertySpec;
        uint256 square;
        string city;
        string country;
        string listType;
        uint256 ownerId;
    }

    struct Transaction {
        address from;
        address to;
        uint256 timestamp;
    }

    struct Escrow {
        address buyer;
        uint256 amount;
        bool completed;
    }

    struct Review {
        address reviewer;
        uint8 rating;
        string comment;
    }

    // EVENTS
    event PropertyListed(
        uint256 indexed id,
        address indexed owner,
        uint256 price,
        string propertyTitle,
        string[] images,
        string description,
        string propertyAddress
    );

    event PropertyUpdated(
        uint256 indexed id,
        address indexed owner,
        uint256 price,
        string propertyTitle,
        string[] images,
        string description,
        string propertyAddress
    );

    event PropertyBought(uint256 indexed id, address indexed buyer);

    event PropertyDeleted(uint256 indexed id, address indexed owner);

    event ReviewAdded(
        uint256 indexed propertyId,
        address indexed reviewer,
        uint8 rating,
        string comment
    );

    mapping(uint256 => Property) private properties;
    mapping(address => uint256[]) private userProperties;
    mapping(uint256 => Transaction[]) private transactionHistory;
    mapping(uint256 => Escrow) private escrows;
    mapping(uint256 => Review[]) private propertyReviews;
    mapping(string => bool) private propertyHashes; // Mapping to store unique property hashes

    // function initialize() public initializer {
    //     propertyIndex = 0;
    // }

    constructor() {}

    function bytes32ToString(
        bytes32 _bytes32
    ) private pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function listProperty(PropertyData memory data) external returns (uint256) {
        require(data.price > 0, "Amount must be greater than 0");

        // Generate a unique hash for the property
        bytes32 propertyHashBytes = keccak256(
            abi.encodePacked(data.propertyAddress, data.city, data.country)
        );
        string memory propertyHash = bytes32ToString(propertyHashBytes);

        require(!propertyHashes[propertyHash], "Property is already listed");

        propertyHashes[propertyHash] = true;

        uint256 propertyId = propertyIndex++;

        Property storage property = properties[propertyId];

        property.propertyId = propertyId;
        property.price = data.price;
        property.owner = msg.sender;
        property.description = data.description;
        property.images = data.images;
        property.propertyAddress = data.propertyAddress;
        property.propertyTitle = data.propertyTitle;
        property.propertyType = data.propertyType;
        property.propertySpec = data.propertySpec;
        property.square = data.square;
        property.city = data.city;
        property.country = data.country;
        property.listType = data.listType;
        property.isListed = true;

        userProperties[msg.sender].push(propertyId); // Store property ID in user's array

        emit PropertyListed(
            propertyId,
            msg.sender,
            data.price,
            data.propertyTitle,
            data.images,
            data.description,
            data.propertyAddress
        );

        return propertyId;
    }

    function updateProperty(
        uint256 propertyId,
        PropertyData memory data
    ) external {
        Property storage property = properties[propertyId];
        require(
            property.owner == msg.sender,
            "You are not the owner of this property"
        );

        property.price = data.price;
        property.propertyTitle = data.propertyTitle;
        property.images = data.images;
        property.description = data.description;
        property.propertyAddress = data.propertyAddress;
        property.propertyType = data.propertyType;
        property.propertySpec = data.propertySpec;
        property.square = data.square;
        property.city = data.city;
        property.country = data.country;
        property.listType = data.listType;

        emit PropertyUpdated(
            propertyId,
            msg.sender,
            data.price,
            data.propertyTitle,
            data.images,
            data.description,
            data.propertyAddress
        );
    }

    function buyProperty(uint256 propertyId) external payable {
        Property storage property = properties[propertyId];
        require(property.isListed, "Property is not listed for sale");
        require(msg.value >= property.price, "Insufficient payment");

        escrows[propertyId] = Escrow({
            buyer: msg.sender,
            amount: msg.value,
            completed: false
        });

        // Mark property as under escrow
        property.isListed = false;
    }

    function completeEscrow(uint256 propertyId) external {
        Escrow storage escrow = escrows[propertyId];
        require(
            escrow.buyer == msg.sender,
            "Only buyer can complete the escrow"
        );
        require(!escrow.completed, "Escrow already completed");

        Property storage property = properties[propertyId];
        address previousOwner = property.owner;
        property.owner = msg.sender;

        // Transfer payment to the previous owner
        payable(previousOwner).transfer(escrow.amount);

        // Mark escrow as completed
        escrow.completed = true;

        // Update userProperties mappings
        _removeUserProperty(previousOwner, propertyId);
        userProperties[msg.sender].push(propertyId);

        // Store transaction in history
        transactionHistory[propertyId].push(
            Transaction({
                from: previousOwner,
                to: msg.sender,
                timestamp: block.timestamp
            })
        );

        emit PropertyBought(propertyId, msg.sender);
    }

    function _removeUserProperty(address user, uint256 propertyId) internal {
        uint256[] storage userPropertyIds = userProperties[user];
        for (uint256 i = 0; i < userPropertyIds.length; i++) {
            if (userPropertyIds[i] == propertyId) {
                userPropertyIds[i] = userPropertyIds[
                    userPropertyIds.length - 1
                ];
                userPropertyIds.pop();
                break;
            }
        }
    }

    function _removePropertyHash(Property memory property) internal {
        bytes32 propertyHashBytes = keccak256(
            abi.encodePacked(
                property.propertyAddress,
                property.city,
                property.country
            )
        );
        string memory propertyHash = bytes32ToString(propertyHashBytes);
        delete propertyHashes[propertyHash];
    }

    function getAllProperties() public view returns (Property[] memory) {
        uint256 itemCount = propertyIndex;
        Property[] memory items = new Property[](itemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            uint256 currentId = i;
            Property storage currentItem = properties[currentId];
            items[i] = currentItem;
        }
        return items;
    }

    function getUserProperties(
        address owner
    ) external view returns (Property[] memory) {
        uint256[] memory userPropertyIds = userProperties[owner];
        uint256 itemCount = userPropertyIds.length;
        Property[] memory userProps = new Property[](itemCount);

        for (uint256 i = 0; i < itemCount; i++) {
            uint256 propertyId = userPropertyIds[i];
            userProps[i] = properties[propertyId];
        }
        return userProps;
    }

    function getProperty(
        uint256 id
    ) external view returns (PropertyDetails memory) {
        Property memory property = properties[id];
        PropertyDetails memory details = PropertyDetails(
            property.propertyId,
            property.owner,
            property.price,
            property.propertyTitle,
            property.images,
            property.description,
            property.propertyAddress,
            property.propertyType,
            property.propertySpec,
            property.square,
            property.city,
            property.country,
            property.listType,
            property.ownerId
        );
        return details;
    }

    // function deleteProperty(uint256 propertyId) external {
    //     Property storage property = properties[propertyId];

    //     // Ensure that the caller is the owner of the property
    //     require(
    //         property.owner == msg.sender,
    //         "You are not the owner of this property"
    //     );

    //     // Remove the property hash from the propertyHashes mapping
    //     _removePropertyHash(property);

    //     // Delete the property from the properties mapping
    //     delete properties[propertyId];

    //     // Remove the property ID from the owner's userProperties array
    //     _removeUserProperty(msg.sender, propertyId);

    //     // Emit event
    //     emit PropertyDeleted(propertyId, msg.sender);
    // }
    function deleteProperty(uint256 propertyId) external {
        Property storage property = properties[propertyId];

        // Ensure that the caller is the owner of the property
        require(
            property.owner == msg.sender,
            "You are not the owner of this property"
        );

        // Remove the property hash from the propertyHashes mapping
        _removePropertyHash(property);

        // Delete the property from the properties mapping
        delete properties[propertyId];

        // Remove the property ID from the owner's userProperties array
        _removeUserProperty(msg.sender, propertyId);

        // Re-organize the properties mapping
        if (propertyId != propertyIndex - 1) {
            Property storage lastProperty = properties[propertyIndex - 1];
            properties[propertyId] = lastProperty;
        }

        // Decrement propertyIndex
        propertyIndex--;

        // Emit event
        emit PropertyDeleted(propertyId, msg.sender);
    }

    function addReview(
        uint256 propertyId,
        uint8 rating,
        string calldata comment
    ) external {
        require(rating > 0 && rating <= 5, "Invalid rating");

        propertyReviews[propertyId].push(
            Review({reviewer: msg.sender, rating: rating, comment: comment})
        );

        emit ReviewAdded(propertyId, msg.sender, rating, comment);
    }

    function getPropertyReviews(
        uint256 propertyId
    ) external view returns (Review[] memory) {
        return propertyReviews[propertyId];
    }

    function getPropertyTransactionHistory(
        uint256 propertyId
    ) external view returns (Transaction[] memory) {
        return transactionHistory[propertyId];
    }
}

// https://thirdweb.com/lisk-sepolia-testnet/0x0e95e00153d5275Ac78Cae9D2f3405347C985a95
