#!/usr/bin/env python
# coding: utf-8
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
graph = nx.from_numpy_matrix(A)
node2vec = Node2Vec(graph, dimensions=64, walk_length=30, num_walks=200)
model = node2vec.fit(window=10, min_count=1, batch_words=4)
# min_count: is the minimun number of counts a wors must have.
# batch_words: are Target size (in words) for batches of examples
# passed to worker threads (and thus cython routines).
# link: https://radimrehurek.com/gensim/models/word2vec.html
list_arrays=[model.wv.get_vector(str(n)) for n in graph.nodes()]
n_cols=list_arrays[0].shape[0] # Number of col
n_rows=len(list_arrays)# Number of rows
emb_pos = np.concatenate(list_arrays).reshape([n_rows,n_cols]) # Concat all the arrays at one.
sim_mat = emb_pos.dot(emb_pos.T) # Obtain dot product of each vector.
np.save(options.output, sim_mat)
