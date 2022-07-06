#!/usr/bin/env python
# coding: utf-8
#import sys
#import traceback
import argparse
import networkx as nx
from node2vec import Node2Vec
import numpy as np

if __name__=="__main__":
        parser = argparse.ArgumentParser(description="Add the adcacency matrix and the output name for the embbeded matrix")
        parser.add_argument("-i", "--input", dest="input",
                help="File in numpy format to use as adjacency matrix")
        parser.add_argument("-o", "--output", dest="output", default="clusters.txt",
                help="Output file")
        options = parser.parse_args()

        # now we got options.input and options.output

A=np.load(options.input)
G = nx.from_numpy_matrix(A) # <- TODO: ADD NODE NAMES (FROM THE LIST).
node2vec = Node2Vec(graph, dimensions=64, walk_length=30, num_walks=200)
model = node2vec.fit(window=10, min_count=1, batch_words=4)
# <- TODO: Create the matrix embedding.