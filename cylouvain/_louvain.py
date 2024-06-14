# Fast implementation of the Louvain algorithm.
# Author: Alexandre Hollocou <alexandre@hollocou.fr>
# License: 3-clause BSD

import numpy as np
from collections import defaultdict

float_type = np.float64
int_type = np.int64

class CythonLouvain(object):

    def __init__(self, adj_matrix):
        self.n_nodes = adj_matrix.shape[0]
        self.graph_neighbors = defaultdict(list)
        self.graph_weights = defaultdict(list)
        indptr = adj_matrix.indptr
        indices = adj_matrix.indices
        data = adj_matrix.data
        for i in range(self.n_nodes - 1):
            for j in range(indptr[i], indptr[i + 1]):
                self.graph_neighbors[i].append(indices[j])
                self.graph_weights[i].append(data[j])
        self.__PASS_MAX = -1
        self.__MIN = 0.0000001
        self.node2com = None
        self.internals = None
        self.loops = None
        self.degrees = None
        self.gdegrees = None
        self.total_weight = None
        self.partition_list = []

    def init_status(self):
        self.node2com = {node: node for node in range(self.n_nodes)}
        self.internals = {node: 0. for node in range(self.n_nodes)}
        self.loops = {node: 0. for node in range(self.n_nodes)}
        self.degrees = {node: 0. for node in range(self.n_nodes)}
        self.gdegrees = {node: 0. for node in range(self.n_nodes)}
        self.total_weight = 0.
        for node in range(self.n_nodes):
            for i, neighbor in enumerate(self.graph_neighbors[node]):
                neighbor_weight = self.graph_weights[node][i]
                if neighbor == node:
                    self.internals[node] += neighbor_weight
                    self.loops[node] += neighbor_weight
                    self.degrees[node] += 2. * neighbor_weight
                    self.gdegrees[node] += 2. * neighbor_weight
                    self.total_weight += 2. * neighbor_weight
                else:
                    self.degrees[node] += neighbor_weight
                    self.gdegrees[node] += neighbor_weight
                    self.total_weight += neighbor_weight
        self.total_weight = self.total_weight / 2.

    def remove(self, node, com, weight):
        self.node2com[node] = -1
        self.degrees[com] = self.degrees[com] - self.gdegrees[node]
        self.internals[com] = self.internals[com] - weight - self.loops[node]

    def insert(self, node, com, weight):
        self.node2com[node] = com
        self.degrees[com] = self.degrees[com] + self.gdegrees[node]
        self.internals[com] = self.internals[com] + weight + self.loops[node]

    def modularity(self, resolution):
        result = 0.
        for com in range(self.n_nodes):
            result += resolution * self.internals[com] / self.total_weight
            result -= ((self.degrees[com] / (2. * self.total_weight)) ** 2)
        return result

    def neighcom(self, node):
        neighbor_weight = defaultdict(float)
        for i, neighbor in enumerate(self.graph_neighbors[node]):
            if neighbor != node:
                neighborcom = self.node2com[self.graph_neighbors[node][i]]
                neighbor_weight[neighborcom] += self.graph_weights[node][i]
        return neighbor_weight

    def one_level(self, resolution):
        modified = True
        nb_pass_done = 0
        cur_mod = self.modularity(resolution)
        new_mod = cur_mod
        while modified and nb_pass_done != self.__PASS_MAX:
            cur_mod = new_mod
            modified = False
            nb_pass_done += 1
            for node in range(self.n_nodes):
                node_com = self.node2com[node]
                neighbor_weight = self.neighcom(node)
                self.remove(node, node_com, neighbor_weight[node_com])
                best_com = node_com
                best_increase = 0.
                for com, weight in neighbor_weight.items():
                    if weight > 0:
                        increase = resolution * weight - \
                                   self.degrees[com] * self.gdegrees[node] / (self.total_weight * 2.)
                        if increase > best_increase:
                            best_increase = increase
                            best_com = com
                self.insert(node, best_com, neighbor_weight[best_com])
                if best_com != node_com:
                    modified = True
            new_mod = self.modularity(resolution)
            if new_mod - cur_mod < self.__MIN:
                break

    def renumber(self):
        com_n_nodes = defaultdict(int)
        for node, com in self.node2com.items():
            com_n_nodes[com] += 1
        com_new_index = {com: i for i, com in enumerate(com_n_nodes) if com_n_nodes[com] > 0}
        final_index = 0
        new_communities = defaultdict(list)
        new_node2com = {}
        for node, com in self.node2com.items():
            if com in com_new_index:
                new_communities[com_new_index[com]].append(node)
                new_node2com[node] = com_new_index[com]
        self.communities = new_communities
        self.node2com = new_node2com

    def induced_graph(self):
        new_n_nodes = len(self.communities)
        new_graph_neighbors = defaultdict(list)
        new_graph_weights = defaultdict(list)
        for com, nodes in self.communities.items():
            to_insert = defaultdict(float)
            for node in nodes:
                for i, neighbor in enumerate(self.graph_neighbors[node]):
                    neighbor_com = self.node2com[neighbor]
                    neighbor_weight = self.graph_weights[node][i]
                    if neighbor == node:
                        to_insert[neighbor_com] += 2 * neighbor_weight
                    else:
                        to_insert[neighbor_com] += neighbor_weight
            for com_weight in to_insert.items():
                new_graph_neighbors[com].append(com_weight[0])
                if com_weight[0] == com:
                    new_graph_weights[com].append(com_weight[1] / 2.)
                else:
                    new_graph_weights[com].append(com_weight[1])
        self.n_nodes = new_n_nodes
        self.graph_neighbors = new_graph_neighbors
        self.graph_weights = new_graph_weights

    def get_partition(self):
        return [self.node2com[i] for i in range(self.n_nodes)]

    def generate_dendrogram(self, resolution):
        mod = None
        new_mod = None
        self.init_status()
        self.one_level(resolution)
        new_mod = self.modularity(resolution)
        self.renumber()
        self.partition_list.append(self.get_partition())
        mod = new_mod
        self.induced_graph()
        self.init_status()

        while True:
            self.one_level(resolution)
            new_mod = self.modularity(resolution)
            if new_mod - mod < self.__MIN:
                break
            self.renumber()
            self.partition_list.append(self.get_partition())
            mod = new_mod
            self.induced_graph()
            self.init_status()

        return self.partition_list

def modularity(partition, adj_matrix, resolution):
    n_nodes = adj_matrix.shape[0]
    indptr = adj_matrix.indptr
    indices = adj_matrix.indices
    data = adj_matrix.data
    part = partition
    links = 0.
    degrees = defaultdict(float)
    for node in range(n_nodes):
        degree = 0.
        for i in range(indptr[node], indptr[node + 1]):
            if indices[i] == node:
                degree += 2 * data[i]
                links += 2 * data[i]
            else:
                degree += data[i]
                links += data[i]
        degrees[node] = degree
    links /= 2

    inc = defaultdict(float)
    deg = defaultdict(float)

    for node in range(n_nodes):
        com = part[node]
        deg[com] += degrees[node]
        for i in range(indptr[node], indptr[node + 1]):
            neighbor = indices[i]
            edge_weight = data[i]
            if part[neighbor] == com:
                if neighbor == node:
                    inc[com] += float(edge_weight)
                else:
                    inc[com] += float(edge_weight) / 2.

    res = 0.
    for com, inc_value in inc.items():
        res += resolution * (inc_value / links) - (deg[com] / (2. * links)) ** 2
    return res

