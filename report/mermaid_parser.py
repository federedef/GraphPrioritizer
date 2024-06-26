import json 
import re
import itertools
# PARSIG JSONs
##############

def load_json(file):
        with open(file,"r") as f:
                json_file = json.load(f)
        return json_file

def extract_argument(command_function, arg):
        value = [el.split("=")[1] for el in command_function if arg in el]
        if len(value) == 0:
                value = ""
        else:
                value = re.sub("'","",value[0])
        return value

def parse_process(processes):
        parsed_processes = ""
        parsed_processes = []
        for process in processes:
                tokens = process.split(" ")
                if "get_similarity" in process:
                        # Ontology semantic
                        sim_type = extract_argument(tokens, "sim_type")
                        parsed_process = f"{sim_type.capitalize()} - Semantic Similarity"
                        parsed_processes.append(parsed_process)
                elif "get_association_values" in process:
                        # Projections
                        if tokens[3] == "'correlation'":
                                pvalue = extract_argument(tokens, "pvalue")
                                corr_type = extract_argument(tokens, "corr_type")
                                if corr_type == "": corr_type = "Pearson"

                                parsed_process = f"{corr_type.capitalize()} Correlation"
                        else:
                                assoc = re.sub("'","",tokens[3])
                                parsed_process = f"{assoc.capitalize()} Projection"
                        parsed_processes.append(parsed_process)
        if parsed_processes == []:
                # Raw
                parsed_processes = ["raw"]

        return parsed_processes

# Getting and parsing edges from json

def get_edge_non_integrated(net2json):
        edges= []
        embeddings = []
        data_version = ""
        whitelist = ""
        normalize_adj = ""
        integrated_layers = ""
        annotations = ""
        embeddings = ""
        phase2nodeid={
        "database": set(),
        "layer":set(),
        "process":set(),
        "matrix_result": {"GSM", "eGSM"},
        "filter":set(),
        "normalize":set(),
        "embedding":set()
        }
        # source 2 layer
        for layer, info in net2json.items():
                if layer == "data_process":
                        data_version = info["Data_version"]
                        whitelist = info["Whitelist"]
                        normalize_adj = info["Normalize_adj"]
                        normalize_adj = extract_argument(normalize_adj[0].split(" "), "by")
                        integrated_layers = info["Integrated_layers"]
                        annotations = info["layers2process"]
                        embeddings = info["Embeddings"]
                        continue
                elif layer in annotations:
                        # Database 2 layer
                        database = info['Database']
                        edges.append((database,layer))
                        # layer 2 process
                        processes = parse_process(info["Build_graph"])
                        for process in processes:
                                edges.append((layer,process))
                                # process 2 filter
                                edges.append((process, "GSM"))
                                if info["Filter"] != []:
   
                                        filt = extract_argument(info["Filter"][0].split(" "), "operation")
                                else:
                                        filt = "No filter"
                                edges.append(("GSM", filt))
                                # filter 2 normalize
                                edges.append((filt, normalize_adj))
                                # normalize 2 embedding
                                for embedding in embeddings:
                                        edges.append((normalize_adj,embedding))
                                        edges.append((embedding,"eGSM"))
                                        phase2nodeid["embedding"].add(embedding)
                                phase2nodeid["database"].add(database)
                                phase2nodeid["layer"].add(layer)
                                phase2nodeid["process"].add(process)
                                phase2nodeid["filter"].add(filt)
                                phase2nodeid["normalize"].add(normalize_adj)
                else:
                        continue
        return edges, phase2nodeid

def get_edge_integrated(net2json):
        info = net2json["data_process"]
        integrated_layers = info["Integrated_layers"]
        embeddings = info["Embeddings"]
        edges = []
        for embedding in embeddings:
                for layer in integrated_layers:
                        edges.append((layer, embedding))
                        edges.append((embedding,"Ranker"))
        return edges

def get_phase2nodeid_integrated(net2json):
        info = net2json["data_process"]
        integrated_layers = info["Integrated_layers"]
        embeddings = info["Embeddings"]
        integration_types = info["integration_types"]
        return {"integrated_layers": integrated_layers, "embeddings": embeddings, "integration_types": integration_types}


# Getting and parsing mermaid from edges and phase2nodeid

id_node = lambda node: re.sub("_|-|,|\(|\)|\[|\]|<br>| ","_",node)

def name_node(node, name_config="capitalize"):
        if name_config == "capitalize":
                nnode = " ".join([word.capitalize() for word in node.split("_")])
        elif name_config == "upper":
                nnode = " ".join([word.upper() for word in node.split("_")])
        elif name_config == "as_is":
                nnode = re.sub("_","",node)
        return nnode


def edges2mermaid(edges, type_edge = "-->", name_config= "capitalize"):
        # style: color and shape.
        mermaid_edges = ""
        all_nodes = {}
        edges = list(set(edges))
        for edge in edges:
                mermaid_edges += edge2mermaid(edge, type_edge, None, name_config)
        mermaid_edges = mermaid_edges.replace("'","")
        return mermaid_edges

def edge2mermaid(edge, type_edge="-->", direction=None, name_config = "capitalize"):
        id1 = id_node(edge[0])
        id2 = id_node(edge[1])
        mermaid_edge = f"  {id1} {type_edge} {id2};\n"
        if direction:
                mermaid_edge = f"  subgraph {'_'.join(edge)}\n    direction {direction}\n    {mermaid_edge}  end\n"
        return mermaid_edge

def add_style_by_phase(phase2nodeid, colours):
        mermaid_txt = ""
        for phase, colour in colours.items():
                for node in phase2nodeid[phase]:
                        node_id = id_node(node)
                        mermaid_txt += f"  style {node_id} fill:{colour}\n"
        return mermaid_txt

def phases2subpgrahs(phase2nodeid, subgraphs):
        mermaid_txt = ""
        for phase, subgraph in subgraphs.items():
                mermaid_line = f"  subgraph {phase}_id[{subgraph.title()}]\n"
                mermaid_line += f"    direction TB\n"
                for node in phase2nodeid[phase]:
                        node_id = id_node(node)
                        mermaid_line += f"    {node_id}\n"
                mermaid_line += f"  end\n"
                mermaid_txt += mermaid_line
        return mermaid_txt

def get_subgraphs_for_neighbor(edges, nodes):
        mermaid_edges = ""
        for node in nodes:
                edges_in_phase = [ edge for edge in edges if edge[0] == node ]
                mermaid_edges += f"  subgraph {node}_id[{node.upper()}]\n"
                for edge in edges_in_phase:
                        id1 = id_node(edge[0])
                        id2 = id_node(edge[1])
                        mermaid_edges += f"    {id1} -- GR --> {id2};\n"
                mermaid_edges += f"  end\n"
        return mermaid_edges

def adding_custom_edges(custom_edges, custom_colours=None, directions=None, name_config = "capitalize"):
        mermaid_txt = ""
        # load custom nodes
        nodes = list(set(itertools.chain(*custom_edges)))
        for node in nodes:
                mermaid_txt += f"  {id_node(node)}(\"{name_node(node, name_config)}\")\n"
        # load edges
        for custom_edge, edge_type in custom_edges.items():
                direction = None 
                if directions:
                        direction = directions.get(custom_edge)
                mermaid_txt += edge2mermaid(custom_edge, edge_type, direction)

        if custom_colours:
                for node, colour in custom_colours.items():
                        node_id = id_node(node)
                        mermaid_txt += f"  style {node_id} fill:{colour}\n"
        return mermaid_txt

def adding_href(nodes):
        mermaid_edges_with_href = ""
        for node in nodes:
                mermaid_edges_with_href += f"  click {node} href \"#{node}\";\n"
        return mermaid_edges_with_href

def select_edges(edges, nodes):
                return [edge for edge in edges if edge[0] in nodes and edge[1] in nodes]
        
def select_nodes_from_classes(classes, classes2nodes):
        nodes = []
        for cla, nodes_cla in classes2nodes.items():
                if cla in classes:
                        nodes.extend(nodes_cla)
        return nodes

def nodes2mermaid_by_phase(phase2nodeid, config_node):
        # config_node node_type, name_parse
        mermaid_txt = ""
        for phase, nodes in phase2nodeid.items():
                name_type = config_node[phase]["name_parse"]
                node_type = config_node[phase]["node_type"]
                for node in nodes:
                        node_id = id_node(node)
                        node_name = name_node(node, name_type)
                        if node_type == "cylinder":
                                mermaid_txt += f"  {node_id}[(\"{node_name}\")]\n"
                        else:
                                mermaid_txt += f"  {node_id}(\"{node_name}\")\n"
        return mermaid_txt