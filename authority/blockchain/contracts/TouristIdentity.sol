// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TouristIdentity {
    
    address public admin;

    struct Tourist {
        string name;
        string nationality;
        string identityHash; // IPFS or secure hash containing KYC documents & validation data
        string emergencyContact;
        bool isValid;
        uint256 validityPeriodEnd;
    }

    mapping(address => Tourist) private tourists;
    mapping(address => bool) public authorizedAuthorities;

    event TouristRegistered(address indexed touristAddress, string name, string identityHash);
    event TouristRevoked(address indexed touristAddress);
    event AuthorityStatusUpdated(address indexed authorityAddress, bool status);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the system administrator");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == admin || authorizedAuthorities[msg.sender], "Caller is not an authorized authority");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Set authorized authorities (e.g., Police stations, Tourism board)
    function setAuthorityStatus(address _authority, bool _status) external onlyAdmin {
        authorizedAuthorities[_authority] = _status;
        emit AuthorityStatusUpdated(_authority, _status);
    }

    // Register a new tourist with digital identity
    function registerTourist(
        address _touristAddress,
        string calldata _name,
        string calldata _nationality,
        string calldata _identityHash,
        string calldata _emergencyContact,
        uint256 _durationInDays
    ) external onlyAuthorized {
        
        tourists[_touristAddress] = Tourist({
            name: _name,
            nationality: _nationality,
            identityHash: _identityHash,
            emergencyContact: _emergencyContact,
            isValid: true,
            validityPeriodEnd: block.timestamp + (_durationInDays * 1 days)
        });

        emit TouristRegistered(_touristAddress, _name, _identityHash);
    }

    // Revoke tourist validity (e.g. if visa expired, left country, or safety breach)
    function revokeTourist(address _touristAddress) external onlyAuthorized {
        require(tourists[_touristAddress].isValid, "Tourist identity is not active or does not exist");
        tourists[_touristAddress].isValid = false;
        
        emit TouristRevoked(_touristAddress);
    }

    // Retrieve tourist identity details
    function getTourist(address _touristAddress) 
        external 
        view 
        returns (
            string memory name,
            string memory nationality,
            string memory identityHash,
            string memory emergencyContact,
            bool isValid,
            uint256 validityPeriodEnd
        ) 
    {
        Tourist memory t = tourists[_touristAddress];
        require(bytes(t.name).length > 0, "Tourist identity does not exist");
        
        // Active check: is valid and not expired
        bool isCurrentlyActive = t.isValid && (block.timestamp <= t.validityPeriodEnd);

        return (
            t.name,
            t.nationality,
            t.identityHash,
            t.emergencyContact,
            isCurrentlyActive,
            t.validityPeriodEnd
        );
    }
}
