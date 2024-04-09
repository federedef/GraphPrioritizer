#!/usr/bin/env python
from NetAnalyzer import Net_parser, NetAnalyzer
import py_exp_calc.exp_calc as pxc
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np


table = []
with open("contingency_input", "r") as t:
    for line in t:
        line = line.strip().split("\t")
        table.append(line)

net = NetAnalyzer(["disease","group"])
for node1, node2 in table:
    net.add_node(node1, "disease")
    net.add_node(node2, "group")
    net.add_edge(node1, node2)

counts = net.get_association_values(["group"],"disease","counts")
print([(edge[0], edge[1], edge[2]) for edge in counts if edge[0] == edge[1]])
# [A, B, 70]
mat, row, col = pxc.pairs2matrix(counts, symm= True)
print("the row is:")
print(row)
print("the col is:")
print(col)
# Create heatmap
plt.figure(figsize=(8, 6))
sns.heatmap(mat, annot=False, xticklabels=col, yticklabels=row,cmap="YlGnBu")
plt.xlabel('Columns')
plt.ylabel('Rows')
# Save the heatmap to a file
plt.savefig('counts.png', bbox_inches='tight')

# Close the plot to prevent displaying it
plt.close()


