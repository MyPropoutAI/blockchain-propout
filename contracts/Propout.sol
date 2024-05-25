// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.9;

contract Propout {
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

    mapping(uint256 => Property) private properties;
    mapping(address => uint256[]) private userProperties;

    constructor() {}

    function listProperty(PropertyData memory data) external returns (uint256) {
        require(data.price > 0, "Amount must be greater than 0");

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
            property.listType
        );
        return details;
    }
}
