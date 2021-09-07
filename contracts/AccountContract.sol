//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract AccountContract is AccessControl {
    uint256 private constant EMPTY = 0;
    
    struct Node {
        address _address;
        uint256 parent;
        uint256 count;
        uint256[] childrens;
        uint deleted;
    }

    bytes32 public constant ADD_ROLE = keccak256("ADD_ROLE");
    bytes32 public constant GRANT_ROLE = keccak256("GRANT_ROLE");
    bytes32 public constant REMOVE_ROLE = keccak256("REMOVE_ROLE");

    address public creator;
    Node[] public nodes;
    mapping(address => uint256) indexOf;

    event AddAccount(address account);
    event RemoveAccount(address account);
    event GrantAddPermission(address account);
    event GrantRemovePermission(address account);
    event GrantGrantPermission(address account);

    modifier canAdd() {
        require(hasRole(ADD_ROLE, msg.sender), "Caller does not have permission to add");
        _;
    }

    modifier canRemove() {
        require(hasRole(REMOVE_ROLE, msg.sender), "Caller does not have permission to remove");
        _;
    }

    modifier canGrant() {
        require(hasRole(GRANT_ROLE, msg.sender), "Caller does not have permission to grant");
        _;
    }

    constructor() {
        require(msg.sender != address(0));
        
        creator = msg.sender;

        Node memory root = Node(creator, EMPTY, 0, new uint256[](0), 0);

        nodes.push(root);
        indexOf[msg.sender] = nodes.length;

        _setupRole(ADD_ROLE, msg.sender);
        _setupRole(REMOVE_ROLE, msg.sender);
        _setupRole(GRANT_ROLE, msg.sender);
    }

    function isExist(address account) internal view returns(bool) {
        uint256 index = indexOf[account];
        if (index == EMPTY) return false;
        if (nodes[index - 1].deleted == 1) return false;
        return true;
    }

    function isChildren(uint256 parent, address account) internal view returns(bool) {
        if (!isExist(account)) return false;

        uint256 index = indexOf[account];
        for (uint i = 0; i < nodes[parent - 1].count; i++) {
            if (nodes[parent - 1].childrens[i] == index) return true;
        }
        return false;
    }

    function isSibling(uint256 index, address account) internal view returns(bool) {
        if (!isExist(account)) return false;
        
        uint256 parent = nodes[index - 1].parent;
        if (parent == EMPTY) return false;
        return isChildren(parent, account);
    }

    function remove(uint256 index) internal {
        uint256 parent = nodes[index - 1].parent;
        for (uint i = 0; i < nodes[parent - 1].count; i++) {
            if (nodes[parent - 1].childrens[i] == index) {
                nodes[parent - 1].childrens[i] = nodes[parent - 1].childrens[nodes[parent - 1].count - 1];
                delete nodes[parent - 1].childrens[nodes[parent - 1].count - 1];
                nodes[parent - 1].count--;
                break;
            }
        }
        remove_tree(index);
    }

    function remove_tree(uint256 parent) internal {
        nodes[parent - 1].deleted = 1;
        indexOf[nodes[parent - 1]._address] = EMPTY;

        for (uint i = 0; i < nodes[parent - 1].count; i++) {
            uint256 child = nodes[parent - 1].childrens[i];
            if (nodes[child - 1].deleted == 1) continue;
            remove_tree(child);
        }
    }

    function insert(uint256 parent, address account) internal {
        uint256 index = nodes.length + 1;

        nodes[parent - 1].childrens.push(index);
        nodes[parent - 1].count++;

        Node memory newNode = Node(account, parent, 0, new uint256[](0), 0);
        nodes.push(newNode);
        indexOf[account] = index;
    }

    function add(address account) public canAdd {
        require(account != msg.sender, 'Can not add own account');
        if (isExist(account)) {
            revert('Account already exist');
        } else if (!isExist(msg.sender)) {
            revert('Caller does not exist');
        } else {
            insert(indexOf[msg.sender], account);

            if (hasRole(ADD_ROLE, msg.sender))  _setupRole(ADD_ROLE, account);
            if (hasRole(REMOVE_ROLE, msg.sender))  _setupRole(REMOVE_ROLE, account);
            if (hasRole(GRANT_ROLE, msg.sender))  _setupRole(GRANT_ROLE, account);
            emit AddAccount(account);
        }
    }

    function remove(address account) public canRemove {
        require(account != creator, 'Can not remove creator account');
        require(account != msg.sender, 'Can not remove own account');
        if (!isExist(account)) {
            revert('Account does not exist');
        } else if (!isExist(msg.sender)) {
            revert('Caller does not exist');
        } else {
            if (!isSibling(indexOf[msg.sender], account)) {
                revert('Caller can not remove account');
            } else {
                remove(indexOf[account]);
                emit RemoveAccount(account);
            }
        }
    }

    function grantAddPermission(address account) public canGrant {
        require(account != msg.sender, 'Can not grant permission to own account.');
        if (!isExist(account)) {
            revert('Account does not exist');
        } else if (!isExist(msg.sender)) {
            revert('Caller does not exist');
        } else {
            if (!isSibling(indexOf[msg.sender], account)) {
                revert('Caller can not grant');
            } else {
                if (!hasRole(ADD_ROLE, account)) {
                    _setupRole(ADD_ROLE, account);
                    emit GrantAddPermission(account);
                } else revert('Account already has permission');
            }
        }
    }

    function grantRemovePermission(address account) public canGrant {
        require(account != msg.sender, 'Can not grant permission to own account.');
        if (!isExist(account)) {
            revert('Account does not exist');
        } else if (!isExist(msg.sender)) {
            revert('Caller does not exist');
        } else {
            if (!isSibling(indexOf[msg.sender], account)) {
                revert('Caller can not grant');
            } else {
                if (!hasRole(REMOVE_ROLE, account)) {
                    _setupRole(REMOVE_ROLE, account);
                    emit GrantAddPermission(account);
                } else revert('Account already has permission');
            }
        }
    }

    function grantGrantPermission(address account) public canGrant {
        require(account != msg.sender, 'Can not grant permission to own account.');
        if (!isExist(account)) {
            revert('Account does not exist');
        } else if (!isExist(msg.sender)) {
            revert('Caller does not exist');
        } else {
            if (!isSibling(indexOf[msg.sender], account)) {
                revert('Caller can not grant');
            } else {
                if (!hasRole(GRANT_ROLE, account)) {
                    _setupRole(GRANT_ROLE, account);
                    emit GrantAddPermission(account);
                } else revert('Account already has permission');
            }
        }
    }

    function size() public view returns (uint256) {
        if (!isExist(msg.sender)) {
            revert('Account does not exist');
        } else {
            return nodes[indexOf[msg.sender] - 1].count;
        }
    }
}