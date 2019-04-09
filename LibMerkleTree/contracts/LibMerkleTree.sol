pragma solidity ^0.5.0;
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

/// @notice Naive merkle tree implementation. 
/// @dev Size is static and nodes are represented in a 2d array
/// @dev items are added directly from hashes, the actual object data -> hash aspect is handled by the inheritor.
library LibMerkleTree {
    
    using SafeMath for uint;

    struct MerkleTree {
        uint8 depth; // Capping depth to 256 as 2^256 is the greatest number representable in a primitive.
        bool initialized;

        uint numLeaves; // There will be 2^depth leaves
        uint currentMaxLeaf;
        bytes32[][] layers;
    }

    /// @notice Initialize the tree to a certain depth. Should only happen once per tree.
    function init(MerkleTree storage mTree, uint8 _depth) internal {
        require(mTree.initialized == false);

        mTree.depth = _depth;
        mTree.layers.length = _depth;
        
        mTree.numLeaves = 2**uint(_depth);
        mTree.currentMaxLeaf = mTree.numLeaves;
    
        for (uint i = 0; i < mTree.depth; i++) {
            mTree.layers[i].length = 2**i;
        }

        mTree.initialized = true;
    }
    
    /// @notice Insert hash into next unused leaf
    function insert(MerkleTree storage mTree, bytes32 _hashValue) internal {
        mTree.layers[mTree.depth - 1][mTree.currentMaxLeaf] = _hashValue;
        mTree.currentMaxLeaf = mTree.currentMaxLeaf.add(1);
        updateTree(mTree);
    }

    /// @notice Insert hash into leaf with given index 
    function setLeaf(MerkleTree storage mTree, uint _index, bytes32 _hashValue) internal {
        mTree.layers[mTree.depth-1][_index] = _hashValue;
        updateTree(mTree);
    }
    
    /// @notice Recalculate all hashes in the tree
    function updateTree(MerkleTree storage mTree) internal {
        // For each layer
        for (uint layer = mTree.depth - 2; layer >= 0; layer--) {
            // For each node
            for (uint node = 0; node < mTree.layers[layer].length; node++) {
                bytes32 leafLeft = mTree.layers[layer+1][node];
                bytes32 leafRight = mTree.layers[layer+1][node + 1];
                mTree.layers[layer][node] = concat(leafLeft, leafRight);
            }
        }
    }

    /// @notice Get the hash of two leaves
    function concat(bytes32 leaf1, bytes32 leaf2) internal pure returns (bytes32){
        return sha256(abi.encodePacked(leaf1, leaf2));
    }
    
    function getRoot(MerkleTree storage mTree) internal view returns (bytes32) {
        return mTree.layers[0][0];
    }

    function readTree(MerkleTree storage mTree) external view returns (bytes32[][] storage) {
        return mTree.layers;
    }
}