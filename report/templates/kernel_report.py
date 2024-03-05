<%
        import json 
        import re
        import itertools   

        # Text
        #######

        def italic(txt):
                return f"<i>{txt}</i>"

        def bold(txt):
                return f"<b>{txt}</b>"

        def collapsable_data(click_title, click_id, container_id, txt):
                collapsable_txt = f"""
                {plotter.create_title(click_title, id=click_id, indexable=False, clickable=True, t_id=container_id)}\n
                <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                        {plotter.create_collapsable_container(container_id, txt)}
                </div>"""
                return collapsable_txt

        def make_title(type, id, sentence):
                if type == "table":
                        key = f"tab:{id}"
                        html_title = f"<p style='text-align:center;'> <b> {type.capitalize()} {plotter.add_table(key)} </b> {sentence} </p>"
                elif type == "figure":
                        key = id
                        html_title = f"<p style='text-align:center;'> <b> {type.capitalize()} {plotter.add_figure(key)} </b> {sentence} </p>"
                return html_title

        def ul(lis):
                txt = '<lu class="body_ul">'
                for li in lis:
                        li = li.split(":")
                        li[0] = bold(li[0])
                        li = ":".join(li)
                        txt += f"<li>{li}</li>\n"
                txt += "</lu>"
                return  txt


        # PARSING TABLES
        ################


        def parsed_string(data, blacklist = ["sim"]):
                words = []
                for word in data.split("_"):
                        for blackword in blacklist:
                                word = re.sub(blackword,"",word)
                        word = word.capitalize()
                        words.append(word)
                parsed_data = " ".join(words)
                return parsed_data

        def parse_data(table, blacklist = ["sim"]):
                parsed_table = []
                for i,row in enumerate(table):
                        parsed_table.append(row)
                        for j,data in enumerate(row):
                                if type(data) == str:
                                        parsed_table[i][j] = parsed_string(data, blacklist)
                                else:
                                        continue
                return parsed_table

        def round_table(table, round_by=2):
                rounded_table = []
                for i,row in enumerate(table):
                        rounded_table.append(row)
                        for j,data in enumerate(row):
                                if data.replace(".", "").isnumeric():
                                        rounded_table[i][j] = str(round(float(data),round_by))
                                else:
                                        continue
                return rounded_table
                
        def order_columns(name, column):
                tab_header = plotter.hash_vars[name].pop(0)
                plotter.hash_vars[name].sort(key=lambda x: x[column])
                plotter.hash_vars[name].insert(0, tab_header)

        def parse_table(name, blacklist=["sim"]):
                plotter.hash_vars[name] = parse_data(plotter.hash_vars[name])
                plotter.hash_vars[name] = round_table(plotter.hash_vars[name])

        if plotter.hash_vars.get('parsed_annotations_metrics') is not None:
                order_columns('parsed_annotations_metrics',0)
                parse_table('parsed_annotations_metrics')

        if plotter.hash_vars.get('parsed_similarity_metrics') is not None:
                order_columns('parsed_similarity_metrics',0)
                parse_table('parsed_similarity_metrics')

        if plotter.hash_vars.get('parsed_filtered_similarity_metrics') is not None:
                order_columns('parsed_filtered_similarity_metrics',0)
                parse_table('parsed_filtered_similarity_metrics')

        if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                order_columns('parsed_uncomb_kernel_metrics',0)
                parse_table('parsed_uncomb_kernel_metrics')

        if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                order_columns('parsed_comb_kernel_metrics',0)
                parse_table('parsed_comb_kernel_metrics')

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
                                                filt = parse_filter(info["Filter"])
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

%>
<% plotter.set_header() %>

<% txt="From Gene Relations to Graph Embeddings" %>
${plotter.create_title(txt, id='report_title', hlevel=1, indexable=True, clickable=False)}
<p> Gene similarity matrices (GSMs) were obtained from different Gene Relations (GR) databases. After completing 
this step for each source, we embedded each individual graph to obtain the embedded GSM (eGSM). 
Finally, we selected different eGSMs to be integrated. This report presents a comprehensive analysis
 of the characteristics of each matrix throughout the various stages of the process, including 
 the graph building process for each layer. </p>

<% txt="Definitions" %>
${plotter.create_title(txt, id="defs", hlevel=2, indexable=True, clickable=False)}
<% 
lis=[
"GSM: Gene Similarity Matrix, which is an adjacency square matrix obtained from gene-to-gene similarity relations graph.",
"eGSM: Embedded Gene Similarity Matrix, which is the gram matrix obtained from the embedding graph process.",
"Seed: Group of genes involved in the same type of disease",
"Ranker: Algorithm for Prioritising Gene Candidates Based on Seed and eGSM",
"Projection: Used here to reference a Bipartite Network Projection. The process of creating a Monopartite Network from a Bipartite one."
]
%>
${ul(lis)}
<% txt="Gene Relation Properties" %>
${plotter.create_title(txt, id='rel_prop', hlevel=2, indexable=True, clickable=False)}

<div style="overflow: hidden";>
        ${make_title("table", "annotation_descriptor", 
                "Number of relations per gene. Showing the minimum (Min), maximum (Max), average and standard deviation from each source.")}
        <div style="overflow: hidden";>
                % if plotter.hash_vars.get('parsed_annotations_metrics') is not None:
                        ${ plotter.table(id='parsed_annotations_metrics', header=True,  text= True, row_names = True, fields= [0,5,4,6,8], styled='dt', border= 2, attrib = {
                                'class' : "table table-striped table-dark"})}
                % endif
        </div>
</div>

<% text=f""" First, we extract the Gene Relations (GR) from different databases. Each GR is then either used directly (Raw) 
or processed (purple boxes) using Projection (Jaccard, Counts), Semantic Similarity (Lin), or Correlation (Pearson, Spearman)
 to obtain a Gene Similarity Matrix (GSM). Finally, after possible filtering and normalization by degree, each GSM is embedded (eGSM)
  using different methods. The following Embeddings were used: Commute time kernel (Ct), random forest Kernel (rf),
   exponential Laplacian kernel (El), kernelized Adjacency Matrix (Ka), Node2vec (Node2vec) and Raw Similarity Matrix (Raw Sim). """ %>
<% txt="Workflow of all studied resources" %>
${plotter.create_title(txt, id='workflow_indv_layers', hlevel=2, indexable=True, clickable=False)}

<div>
<%      
        net2json = load_json("./net2json")
        annotations = net2json["data_process"]["layers2process"]
        subgraphs = {"normalize": "Adjacency Matrix <br> Normalization", "embedding": "Embedding", "control_embedding": "Control"}   
        custom_edges = { ("eGSM", "Ranker"):"-->",("Seeds","Ranker"):"-->"}
        custom_colours = {"Seeds": "#B7E4FF", "Ranker":"#FFA8A8"}
        edges, phase2nodeid = get_edge_non_integrated(net2json) # Parse connections from json
        print(phase2nodeid)
        # building mermaid body
        # load nodes
        mermaid_body = nodes2mermaid_by_phase(phase2nodeid, 
        {
        "database": {"name_parse": "upper", "node_type": "cylinder"},
        "layer":{"name_parse": "capitalize", "node_type": "round"},
        "process":{"name_parse": "capitalize", "node_type": "round"},
        "matrix_result": {"name_parse": "as_is", "node_type": "round"},
        "filter":{"name_parse": "capitalize", "node_type": "round"},
        "normalize":{"name_parse": "capitalize", "node_type": "round"},
        "embedding": {"name_parse": "capitalize", "node_type": "round"}
        })
        mermaid_body += add_style_by_phase(phase2nodeid, {"process": "#BF7AE7","matrix_result": "#95B9F3"})
        # load edges
        mermaid_body += edges2mermaid(select_edges(edges, select_nodes_from_classes(["layer","process","filter","matrix_result","normalize","embedding"], phase2nodeid)), "-->", "upper") 
        all_embeddings = {'el', 'node2vec', 'ka', 'rf', 'raw_sim'}
        phase2nodeid["embedding"] =  all_embeddings.intersection({'el', 'node2vec', 'ka', 'rf'})
        phase2nodeid["control_embedding"] = all_embeddings.intersection({'raw_sim'})
        mermaid_body += get_subgraphs_for_neighbor(edges, phase2nodeid["database"]) # subgraph the neighboor
        mermaid_body += phases2subpgrahs(phase2nodeid, subgraphs)
        mermaid_body += adding_href(phase2nodeid["layer"])
        #mermaid_body += adding_custom_edges(custom_edges, custom_colours, None, "as_is")
        mermaid_body += f"  style normalize_id text-align:center\n"
        mermaid_body = re.sub("No filter", " ", mermaid_body)
        graph=f"""---\nTitle: Flux\nconfig:\n  theme: base\n---\ngraph LR;\n{mermaid_body}"""
%>
        ${ plotter.mermaid_chart(graph)}
        <p style="text-align:center;"><b> Figure ${plotter.add_figure("worflow_individual_layers")} </b> Workflow of all studied resources. ${text} </p>

</div>

<% txt="Individual Processing Graph Steps" %>
${plotter.create_title(txt, id="indv_process_graph_steps", hlevel=2, indexable=True, clickable=False)}
    <%
        table = plotter.hash_vars["parsed_final_stats_by_steps"]
        ids = list(set([ row[1] for i,row in enumerate(table) if i > 0]))
        ids.sort()
    %>

    <% macro_click_txt = [] %>
    % for elem in ids:
        <%

                def parse_individual_processing(id_layer):
                        if id_layer == "string_ppi" or id_layer == "kim_coess_gene":
                                return ["jaccard"]
                        build_graph = net2json[id_layer]["Build_graph"]
                        build_graph += net2json[id_layer]["Filter"]
                        process_labels = [ elem.split("'")[-2].split("_")[-2] for elem in build_graph if elem.startswith("write_stats_from_matrix") or elem.startswith("normalize_matrix")]
                        if net2json["data_process"].get("Normalize_adj"):
                                process_labels.append("Normalization")
                        return process_labels

                proclabel2define={
                "semLin": "Semantic similarity between ontology profiles annotated for each gene",
                "RawWeights": "raw weights extracted from data source",
                "Normalization": "Adjacency Matrix Normalization",
                "filterJaccardByCounts": "Filtering Jaccard values based on Counts",
                "SpearmanCorr": "Spearman correlation based on gene profiles from X",
                "PearsonCorr": "Pearson correlation based on gene profiles from X",
                "jaccard": "Jaccard Projection",
                "counts": "Counts of intersected neighborhood Projection",
                "kim_coess_gene": "raw intersection"
                }
                processes = parse_individual_processing(re.sub("_sim","",elem))
                adding_text = []
                for idx, process in enumerate(processes):
                        adding_text.append(f"{idx+1}, {proclabel2define[process]} ({process})")
                adding_text = ";".join(adding_text) + "."

        %>
        <% key = "parsed_final_stats_by_steps_" + elem %>
        <% subtable = [row for i, row in enumerate(table) if i == 0 or row[1] == elem] %>
        <% plotter.hash_vars[key] = subtable %>
        <% figure1= plotter.barplot(id=key, fields= [2,22] , header= True, height= '400px', width= '400px', x_label= 'Number of nodes', var_attr= [2],
                                title = "(A) Network Size",
                                config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'vertical',
                                        'colorBy' : 'Step',
                                        'setMinX': 0,
                                        "smpLabelRotate": 90,
                                        "titleFontStyle": "italic",
                                        "titleScaleFontFactor": 0.3
                                        }) %>
        <% figure2 = plotter.barplot(id=key, fields= [2,6] , header= True, height= '400px', width= '400px', x_label= 'Density (%)', var_attr= [2],
                                title = "(B) Network Density",
                                config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'vertical',
                                        'colorBy' : 'Step',
                                        'setMinX': 0,
                                        "smpLabelRotate": 90,
                                        "titleFontStyle": "italic",
                                        "titleScaleFontFactor": 0.3
                                        })%>
        <% figure3 = plotter.line(id= key, fields= [2, 7, 19, 20, 21], header= True, row_names= True,
                        responsive= False,
                        height= '400px', width= '400px', x_label= 'Edge Value',
                        title= " (C) Edges value distribution",
                        config= {
                                'showLegend' : True,
                                'graphOrientation' : 'vertical',
                                'colorBy' : 'Step',
                                "smpLabelRotate": 90,
                                "titleFontStyle": "italic",
                                "titleScaleFontFactor": 0.3
                                })%>
        <% text = f"""<p style="text-align:center;"><b> Figure {plotter.add_figure(key)} 
        </b> {parsed_string(elem)} descriptive stats during network processing. Number of nodes (A), density (B) and summary of edge values (C) on the network. 
        Labels on x axis indicate diffente stages during the network building: {adding_text} </p>""" %>
        <% click_back="""<a href="#workflow_indv_layers">Back to Workflow</a>""" %>
        <%macro_txt = collapsable_data(f"{parsed_string(elem)}", re.sub('_sim','',elem), f"{elem}_container" ,"\n".join([f"<p id={re.sub('_sim','',elem)}></p>",figure1,figure2,figure3,text,click_back]))%>
        <% macro_click_txt.append(macro_txt) %>
    % endfor
    ${collapsable_data("All individual process summary", 'clickme_id'+"general", 'container'+"general","\n".join(macro_click_txt))}


<% txt="Selection and Integration of individual networks Workflow" %>
${plotter.create_title(txt, id="sel_int_workflow", hlevel=2, indexable=True, clickable=False)}
<div>
<%  

        {"integrated_layers": integrated_layers, "embeddings": embeddings, "integration_types": integration_types}
        phase2nodeid = get_phase2nodeid_integrated(net2json)
        custom_edges = {
        ("integration_types_id","Integrated <br> eGSM"): "-->",
        ("embeddings_id","integration_types_id"): "-->", 
        ("integrated_layers_id","embeddings_id"): "-->"}      
        custom_colours = { "Integrated <br> eGSM": "#95B9F3"}
        subgraphs = {"integrated_layers": "Selected layers","embeddings": "Embeddings", "integration_types": "Integration"}   
        mermaid_body = nodes2mermaid_by_phase(phase2nodeid, 
        {
        "integrated_layers": {"name_parse": "capitalize", "node_type": "round"},
        "embeddings":{"name_parse": "capitalize", "node_type": "round"},
        "integration_types":{"name_parse": "capitalize", "node_type": "round"}
        })
        mermaid_body += phases2subpgrahs(phase2nodeid, subgraphs)
        mermaid_body += adding_custom_edges(custom_edges, custom_colours, None, "as_is")
        graph=f"""---\nTitle: Flux\nconfig:\n  theme: base\n---\nflowchart TB;\n{mermaid_body}"""
%>
        ${ plotter.mermaid_chart(graph)}
        <% text=f""" Invididual raw and embedding networks were selected based on performance. Those 
        with the best predictive power were integrated all in one similarity matrix, based on 
        different integration methods ({italic("Mean")}, {italic("Max")}, {italic("Integration Mean By Presence")}, {italic("Median")}"""%>
        ${make_title("figure", "workflow_integration", text)}
</div>

<% txt="Embedding Process" %>
${plotter.create_title(txt, id="emb_process", hlevel=2, indexable=True, clickable=False)}



<div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
        % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                        ${plotter.barplot(id='parsed_uncomb_kernel_metrics', fields= [2,6] , header= True, height= '400px', width= '400px', x_label= 'Matrix Non Zero Density (%)', var_attr= [1,2],
                                title = "(A) Individual eGSM",
                                config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'horizontal',
                                        'colorBy' : 'Embedding',
                                        "segregateSamplesBy": ["Net"],
                                        "axisTickScaleFontFactor": 0.2,
                                        'setMinX': 0,
                                        "titleFontStyle": "italic",
                                        "titleScaleFontFactor": 0.3
                                        })}
        % endif
        % if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                        ${plotter.barplot(id='parsed_comb_kernel_metrics', fields= [2,6] , header= True, height= '400px', width= '400px', x_label= 'Matrix Non Zero Density (%)', var_attr= [1,2],
                                title = "(B) Integrated eGSM",
                                config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'horizontal',
                                        'colorBy' : 'Embedding',
                                        'segregateSamplesBy': "Integration",
                                        'setMinX': 0,
                                        "titleFontStyle": "italic",
                                        "titleScaleFontFactor": 0.3
                                        })}
        % endif

        ${make_title("figure","density_summ", f"""Summary of eGSM density (%) before (A) and after (B) integration.
        Both plots are segreggated by {italic("individual graph source")} (A) or {italic("integration method")} (B), coloured by embedding process.""")}
</div>

<% txt = [] %>
% if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
        <% txt.append(make_title("table", "unc_emb_matrix",
                f"""Summary metrics for each eGSM obtained by every source and embedding. Showing metrics on size
                ({italic("Matrix Dimensions")}, {italic("Matrix Elements")}) and density 
                ({italic("Matrix Elements Non Zero")}, {italic("Matrix non zero density")}) matrix.""")) %>
        <% txt.append(plotter.table(id='parsed_uncomb_kernel_metrics', text= True, header=True, row_names = True, fields= [1,2,3,4,5,6], styled='dt', cell_align= ['left', 'left', 'center', 'center', 'center', 'center'], border= 2,attrib= {
                        'style' : 'margin-left: auto; margin-right:auto;',
                        'cellspacing' : 0,
                        'cellpadding' : 2})) %>
        ${collapsable_data("Individual eGSM Matrix Sumary", None, "individual_egsm_matrix_summ", "\n".join(txt))}
% endif
% if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
        <% txt = [] %>
        <% txt.append(make_title("table", "c_emb_matrix",
                f"""Summary metrics for each eGSM obtained after integration step. Showing metrics on size
                ({italic("Matrix Dimensions")}, {italic("Matrix Elements")}) and density 
                ({italic("Matrix Elements Non Zero")}, {italic("Matrix non zero density")}) matrix."""))%>
        <% txt.append(plotter.table(id='parsed_comb_kernel_metrics', text= True, header=True, row_names = True, fields= [1,2,3,4,5,6], styled='dt', cell_align= ['left', 'left', 'center', 'center', 'center', 'center'], border= 2,attrib= {
                        'style' : 'margin-left: auto; margin-right:auto;',
                        'cellspacing' : 0,
                        'cellpadding' : 2})) %>
        ${collapsable_data("Integrated eGSM Matrix Sumary", None, "integrated_egsm_matrix_summ", "\n".join(txt))}
% endif

<% txt = [] %>
% if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                <% txt.append(plotter.scatter2D(id= 'parsed_uncomb_kernel_metrics', title= "(A) Size vs Density on eGSM", header= True, fields = [4,6], x_label = 'Number of posible relations', y_label = 'Matriz Non Zero Density', var_attr=[1,2], alpha = 0.3,
                config= {
                'showLegend' : True,
                "colorBy":"Net",
                "segregateVariablesBy":"Embedding",
                "titleFontStyle": "italic",
                "titleScaleFontFactor": 0.3,
                })) %>
% endif

% if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                <% txt.append(plotter.scatter2D(id= 'parsed_comb_kernel_metrics', title= "(B) Size vs Density on eGSM", header= True, fields = [4,6], x_label = 'Number of posible relations', y_label = 'Matrix Non Zero Density', var_attr=[1,2], alpha = 0.3,
                config= {
                'showLegend' : True,
                "colorBy":"Integration",
                "segregateVariablesBy":"Embedding",
                "titleFontStyle": "italic",
                "titleScaleFontFactor": 0.3,
                })) %>

% endif
<%txt.append(make_title("figure", "figure_sizeVSdensity", "Size vs Density on eGSM before (A) and after (B) integration step, respectively.  The plots are categorised according to the embedding methods used, with colours representing individual graphs in (A) or integration methods in (B)."))%>
${collapsable_data("Density vs Size", None, "dens_size", "\n".join(txt))}


<% txt = [] %>
% if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                <% txt.append(plotter.line(id= "parsed_uncomb_kernel_metrics", fields= [1, 19, 20, 21], var_attr=[2], header= True, row_names= True,
                responsive= False,
                height= '400px', width= '400px', x_label= 'Embedding \n Values',
                title= "(A) Embedding values \nbefore integration",
                config= {
                        'showLegend' : True,
                        'graphOrientation' : 'vertical',
                        'segregateSamplesBy' : 'Embedding',
                        "smpLabelRotate": 45,
                        "titleFontStyle": "italic",
                        "titleScaleFontFactor": 0.3
                        }))%>
% endif
% if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                <% txt.append(plotter.line(id= "parsed_comb_kernel_metrics", fields= [1, 19, 20, 21], var_attr= [2], header= True, row_names= True,
                responsive= False,
                height= '400px', width= '400px', x_label= 'Embedding \n Values',
                title= "(B) Embedding values \nafter integration",
                config= {
                        'showLegend' : True,
                        'graphOrientation' : 'vertical',
                        'segregateSamplesBy' : 'Embedding',
                        "smpLabelRotate": 45,
                        "titleFontStyle": "italic",
                        "titleScaleFontFactor": 0.3,
                        })) %>
% endif

<% txt.append(make_title("figure","summ_matrix_values", f"""Summary of eGSM values 
                before (A) and after (B) integration. Both plots are segreggated by embedding type
                 and x axis label points to {italic("individual graph source")} (A) or {italic("integration method")} (B).""")) %>
${collapsable_data("Embedding values Summary", None, "embd_values_summ", "\n".join(txt))}