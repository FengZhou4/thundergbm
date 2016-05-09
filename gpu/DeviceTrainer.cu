/*
 * DeviceTrainer.cu
 *
 *  Created on: 5 May 2016
 *      Author: Zeyi Wen
 *		@brief: 
 */

#include "DeviceTrainer.h"
#include "gbdtGPUMemManager.h"

/**
 * @brief: grow the tree by splitting nodes to the full extend
 */
void DeviceTrainer::GrowTree(RegTree &tree)
{
	int nNumofSplittableNode = 0;

	//copy the root node to GPU
	GBDTGPUMemManager manager;
	manager.MemcpyHostToDevice(tree.nodes[0], manager.pSplittableNode, sizeof(TreeNode));
	nNumofSplittableNode++;

	//split node(s)
	int nCurDepth = 0;
	while(nNumofSplittableNode > 0 && nCurDepth <= m_nMaxDepth)
	{
		splitter.m_nCurDept = nCurDepth;
//		cout << "splitting " << nCurDepth << " level..." << endl;

		int bufferSize = splitter.mapNodeIdToBufferPos.size();//maps node id to buffer position

		//efficient way to find the best split
		clock_t begin_find_fea = clock();
		vector<SplitPoint> vBest;
		vector<nodeStat> rchildStat, lchildStat;
		splitter.FeaFinderAllNode(vBest, rchildStat, lchildStat);

		clock_t end_find_fea = clock();
		total_find_fea_t += (double(end_find_fea - begin_find_fea) / CLOCKS_PER_SEC);

		//split all the splittable nodes
		clock_t start_split_t = clock();
		bool bLastLevel = false;
		if(nCurDepth == m_nMaxDepth)
			bLastLevel = true;
	vector<TreeNode*> splittableNode;
		splitter.SplitAll(splittableNode, vBest, tree, m_nNumofNode, rchildStat, lchildStat, bLastLevel);
		clock_t end_split_t = clock();
		total_split_t += (double(end_split_t - start_split_t) / CLOCKS_PER_SEC);

		nCurDepth++;
	}

	clock_t begin_prune = clock();
	pruner.pruneLeaf(tree);
	clock_t end_prune = clock();
	total_prune_t += (double(end_prune - begin_prune) / CLOCKS_PER_SEC);
}
