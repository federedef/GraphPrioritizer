<%
        import json 
        import re

        # Text
        #######

        def italic(txt):
                return f"<i>{txt}</i>"

        def collapsable_data(click_title, click_id, txt):
                collapsable_txt = f"""
                {plotter.create_clickable_title(click_title, click_id)}\n
                <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                        {plotter.create_collapsable_container(click_id, txt)}
                </div>"""
                print(collapsable_txt)
                return collapsable_txt

        def make_title(type, id, sentence):
                if type == "table":
                        key = f"tab:{id}"
                        html_title = f"<p style='text-align:center;'> <b> {type.capitalize()} {plotter.add_table(key)} </b> {sentence} </p>"
                elif type == "figure":
                        key = id
                        html_title = f"<p style='text-align:center;'> <b> {type.capitalize()} {plotter.add_figure(key)} </b> {sentence} </p>"
                return html_title

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

        net2json = load_json("./net2json")
        annotations = net2json["data_process"]["layers2process"]

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
                        name_node = " ".join([word.capitalize() for word in node.split("_")])
                elif name_config == "upper":
                        name_node = " ".join([word.upper() for word in node.split("_")])
                return name_node


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
                edge1 = name_node(edge[0], name_config)
                edge2 = name_node(edge[1], name_config)
                mermaid_edge = f"  {id1}(\"{edge1}\") {type_edge} {id2}(\"{edge2}\");\n"
                if direction:
                        mermaid_edge = f"  subgraph {'_'.join(edge)}\n    direction {direction}\n    {mermaid_edge}  end\n"
                return mermaid_edge

        def add_style(phase2nodeid, colours):
                mermaid_txt = ""
                for phase, colour in colours.items():
                        for node in phase2nodeid[phase]:
                                node_id = id_node(node)
                                mermaid_txt += f"  style {node_id} fill:{colour}\n"
                return mermaid_txt

        def add_subgraphs(phase2nodeid, subgraphs):
                mermaid_txt = ""
                for phase, subgraph in subgraphs.items():
                        mermaid_line = f"  subgraph {phase}_id[{subgraph.title()}]\n"
                        mermaid_line += f"    direction TB\n"
                        for node in phase2nodeid[phase]:
                                node_id = id_node(node)
                                node_name = name_node(node)
                                mermaid_line += f"    {node_id}[{node_name}]\n"
                        mermaid_line += f"  end\n"
                        mermaid_txt += mermaid_line
                return mermaid_txt

        def get_database_subgraphs(edges, phase2nodeid):
                mermaid_edges = ""
                for node in phase2nodeid["database"]:
                        edges_in_phase = [ edge for edge in edges if edge[0] == node ]
                        mermaid_edges += f"  subgraph {node}_id[{node.upper()}]\n"
                        for edge in edges_in_phase:
                                id1 = id_node(edge[0])
                                id2 = id_node(edge[1])
                                edge1 = name_node(edge[0])
                                edge2 = name_node(edge[1])
                                mermaid_edges += f"    {id1}[(\"{edge1}\")] -- GR --> {id2}(\"{edge2}\");\n"
                        mermaid_edges += f"  end\n"
                return mermaid_edges

        def adding_custom_edges(custom_edges, custom_colours=None, directions=None):
                mermaid_txt = ""
                for custom_edge, edge_type in custom_edges.items():
                        direction = None 
                        if directions:
                                direction = directions.get(custom_edge)
                        mermaid_txt += edge2mermaid(custom_edge,edge_type,direction)

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


%>


<div style="width:90%; background-color:#FFFFFF; margin:50 auto; align-content: center;">

        <h1 style="text-align:center; background-color:#ecf0f1, color: powderblue; ">Analysis of the algorithm: From embeddings to prioritized genes.</h1>

        <p> The algorithm transformed the similarity matrix to make it compatible with the embedding process. Once this was done for each network and embedding type, it was integrated by embedding type. Below there is a general analysis of the properties of each matrix in the different phases of the process, including the graph building process for each layer. </p>

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue; text-decoration: underline;"> Annotation Properties </h3>


        <div style="overflow: hidden";>
                ${make_title("table", "annotation_descriptor", 
                        "Number of relations by gene. Showing the minimum (Min), maximum (Max), average and standard deviation from each source.")}
                <div style="overflow: hidden";>
                        % if plotter.hash_vars.get('parsed_annotations_metrics') is not None:
                                ${ plotter.table(id='parsed_annotations_metrics', header=True,  text= True, row_names = True, fields= [0,5,4,6,8], styled='dt', border= 2, attrib = {
                                        'class' : "table table-striped table-dark"})}
                        % endif
                </div>
        </div>

        <% text=f""" First, we extract the Gene Relations (GR) from different databases. 
        Then each GR is used directly (Raw) or processed (purple boxes) by Projection (Jaccard, Counts), Semantic Similarity
         (Lin) or Correlation (Pearson, Spearman) to obtain a Gene Similarity Matrix (GSM). Finally, after possible filtering and normalization by degree, every GSM is embedded (eGSM) by diferrent methods: 
         Commute time kernel (Ct), random forest Kernel (rf), exponential laplacian kernel (El), kernelized Adjacency Matrix (Ka), Node2vec (Node2vec) and Raw Similarity Matrix (Raw Sim). """ %>
        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue; text-decoration: underline;", id="workflow_indv_layers"> Workflow of all studied resources </h3>
        <div>
        <%   
                colours = {"process": "#BF7AE7"}
                subgraphs = {"normalize": "Adjacency Matrix <br> Normalization", "embedding": "Embedding"}   
                custom_edges = { ("eGSM", "Ranker"):"-->",("Seeds","Ranker"):"-->"}
                custom_colours = {"Seeds": "#B7E4FF", "eGSM": "#95B9F3", "Ranker":"#FFA8A8", "GSM": "#95B9F3"}
                edges, phase2nodeid = get_edge_non_integrated(net2json)
                mermaid_body = get_database_subgraphs(edges, phase2nodeid)
                mermaid_body += edges2mermaid([edge for edge in edges if edge[0] not in phase2nodeid["database"]], "-->", "upper")
                print(50*"ey\n")
                print(edges2mermaid([edge for edge in edges if edge[0] not in phase2nodeid["database"]], "-->", "upper"))
                print(50*"ey\n")
                mermaid_body += add_style(phase2nodeid, colours)
                mermaid_body += add_subgraphs(phase2nodeid, subgraphs)
                mermaid_body += adding_href(phase2nodeid["layer"])
                mermaid_body += adding_custom_edges(custom_edges, custom_colours, custom_directions)
                mermaid_body += f"  style normalize_id text-align:center\n"
                mermaid_body = re.sub("No filter", " ", mermaid_body)
                print(mermaid_body)
                print(mermaid_body)
                graph=f"""---\nTitle: Flux\nconfig:\n  theme: base\n---\ngraph LR;\n{mermaid_body}"""
                print(graph)
        %>
                ${ plotter.mermaid_chart(graph)}
                <p style="text-align:center;"><b> Figure ${plotter.add_figure("worflow_individual_layers")} </b> Workflow of all studied resources. ${text} </p>

        </div>

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue; text-decoration: underline;"> Individual Processing Graph Steps </h3>

            <%
                table = plotter.hash_vars["parsed_final_stats_by_steps"]
                ids = list(set([ row[1] for i,row in enumerate(table) if i > 0]))
                ids.sort()
            %>

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
                        "kim_coess_gene": "raw intersaction"
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
                Labels on x axis indicate diffente stages of the network building: {adding_text} </p>""" %>
                <% click_back="""<a href="#workflow_indv_layers">Back to Workflow</a>""" %>
                <p id="${re.sub('_sim','',elem)}"></p>
                ${ plotter.create_clickable_title(f"{parsed_string(elem)} (click me)", 'clickme_id'+key) }
                <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                                ${ plotter.create_collapsable_container('clickme_id'+key, "\n".join([figure1,figure2,figure3,text,click_back]))}
                </div>
            % endfor
        
        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue; text-decoration: underline;"> Selection and Integration of individual networks Workflow </h3>
        <div>
        <%
                import itertools     

                {"integrated_layers": integrated_layers, "embeddings": embeddings, "integration_types": integration_types}
                phase2nodeid = get_phase2nodeid_integrated(net2json)
                custom_edges = {
                ("integration_types_id","Similarity <br> Matrix"): "-->",
                ("Similarity <br> Matrix","Ranker"):"-->",
                ("Seeds","Ranker"):"-->",
                ("embeddings_id","integration_types_id"): "-->", 
                ("integrated_layers_id","embeddings_id"): "-->", 
                ("integration_types_id","Ranker"): "-->"}      
                custom_colours = {"Seeds": "#B7E4FF", "Similarity <br> Matrix": "#95B9F3", "Ranker":"#FFA8A8"}
                subgraphs = {"integrated_layers": "Selected layers","embeddings": "Embeddings", "integration_types": "Integration"}   
                mermaid_body = add_subgraphs(phase2nodeid, subgraphs)
                mermaid_body += adding_custom_edges(custom_edges, custom_colours)
                #mermaid_body += edges2mermaid(itertools.product(phase2nodeid["integrated_layers"],phase2nodeid["embeddings"]), type_edge = "-->")
                #mermaid_body += edges2mermaid(itertools.product(phase2nodeid["embeddings"],phase2nodeid["integration_types"]), type_edge = "-->")
                #mermaid_body += edges2mermaid(itertools.product(phase2nodeid["integration_types"],["ranker"]), type_edge = "-->")
                #edges=edges2mermaid(get_edge_integrated(net2json))
                print(mermaid_body)
                graph=f"""---\nTitle: Flux\nconfig:\n  theme: base\n---\nflowchart TB;\n{mermaid_body}"""
        %>
                ${ plotter.mermaid_chart(graph)}
                <% text=f""" Invididual raw and embedding networks were selected based on performance. Those 
                with the best predictive power were integrated all in one similarity matrix, based on 
                different integration methods ({italic("Mean")}, {italic("Max")},{italic("Integration Mean By Presence")},{italic("Median")}"""%>
                ${make_title("figure", "workflow_integration", text)}
        </div>

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue; text-decoration: underline;"> Embedding Process </h3>

        <div style="overflow: hidden;">
                ${make_title("table", "unc_emb_matrix",
                        f"""Summary metrics for each Similarity Matrix obtained by every source and embedding. Showing metrics on size
                         ({italic("Matrix Dimensions")}, {italic("Matrix Elements")}) and density 
                         ({italic("Matrix Elements Non Zero")}, {italic("Matrix non zero density")}) matrix.""")}
                % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                                ${plotter.table(id='parsed_uncomb_kernel_metrics', text= True, header=True, row_names = True, fields= [1,2,3,4,5,6], styled='dt', cell_align= ['left', 'left', 'center', 'center', 'center', 'center'], border= 2,attrib= {
                                        'style' : 'margin-left: auto; margin-right:auto;',
                                        'cellspacing' : 0,
                                        'cellpadding' : 2})}
                % endif
                ${make_title("table", "c_emb_matrix",
                        f"""Summary metrics for each Aggregated Matrix obtained after integration step. Showing metrics on size
                         ({italic("Matrix Dimensions")}, {italic("Matrix Elements")}) and density 
                         ({italic("Matrix Elements Non Zero")}, {italic("Matrix non zero density")}) matrix.""")}
                % if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                                ${plotter.table(id='parsed_comb_kernel_metrics', text= True, header=True, row_names = True, fields= [1,2,3,4,5,6], styled='dt', cell_align= ['left', 'left', 'center', 'center', 'center', 'center'], border= 2,attrib= {
                                        'style' : 'margin-left: auto; margin-right:auto;',
                                        'cellspacing' : 0,
                                        'cellpadding' : 2})}
                % endif
                

        </div>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                                ${ plotter.scatter2D(id= 'parsed_uncomb_kernel_metrics', title= "(A) Size vs Density Individual Networks", header= True, fields = [4,6], x_label = 'Size', y_label = 'Density', var_attr=[1,2], alpha = 0.3,
                             config= {
                                'showLegend' : True,
                                "colorBy":"Net",
                                "segregateVariablesBy":"Kernel",
                                "titleFontStyle": "italic",
                                "titleScaleFontFactor": 0.3,
                                })}
                % endif

                % if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                                ${ plotter.scatter2D(id= 'parsed_comb_kernel_metrics', title= "(B) Size vs Density Aggragated Networks", header= True, fields = [4,6], x_label = 'Size', y_label = 'Density', var_attr=[1,2], alpha = 0.3,
                             config= {
                                'showLegend' : True,
                                "colorBy":"Integration",
                                "segregateVariablesBy":"Kernel",
                                "titleFontStyle": "italic",
                                "titleScaleFontFactor": 0.3,
                                })}

                % endif
        </div>
                ${make_title("figure", "figure_sizeVSdensity", "Size vs Density Network before (A) and after (B) integration step. Both plots are segregated based on different embedding method perform and colors represent different individual graphs (A) or integration method (B).")}


        <% txt = [] %>
        % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                        <% txt.append(plotter.barplot(id='parsed_uncomb_kernel_metrics', fields= [2,6] , header= True, height= '400px', width= '400px', x_label= 'Density (%)', var_attr= [1,2],
                                title = "(A) Individual Networks",
                                config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'horizontal',
                                        'colorBy' : 'Kernel',
                                        "segregateSamplesBy": ["Net"],
                                        "axisTickScaleFontFactor": 0.2,
                                        'setMinX': 0,
                                        "titleFontStyle": "italic",
                                        "titleScaleFontFactor": 0.3
                                        })) %>
        % endif
        % if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                        <% txt.append(plotter.barplot(id='parsed_comb_kernel_metrics', fields= [2,6] , header= True, height= '400px', width= '400px', x_label= 'Density (%)', var_attr= [1,2],
                                title = "(B) Integrated Networks",
                                config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'horizontal',
                                        'colorBy' : 'Kernel',
                                        'segregateSamplesBy': "Integration",
                                        'setMinX': 0,
                                        "titleFontStyle": "italic",
                                        "titleScaleFontFactor": 0.3
                                        })) %>
        % endif

        <% txt.append(make_title("figure","density_summ", f"""Summary of network density (%) 
                        before (A) and after (B) integration. Both plots are segreggated by {italic("individual graph source")} (A) or {italic("integration method")} (B), 
                        coloured by embedding process.""")) %>
        ${collapsable_data("Density summary (click me)", "dens_summ", "\n".join(txt))}



        <% txt = [] %>
        % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                        <% txt.append(plotter.line(id= "parsed_uncomb_kernel_metrics", fields= [1, 19, 20, 21], var_attr=[2], header= True, row_names= True,
                        responsive= False,
                        height= '400px', width= '400px', x_label= 'Embedding \n Values',
                        title= "(A) Embedding values \nbefore integration",
                        config= {
                                'showLegend' : True,
                                'graphOrientation' : 'vertical',
                                'segregateSamplesBy' : 'Kernel',
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
                                'segregateSamplesBy' : 'Kernel',
                                "smpLabelRotate": 45,
                                "titleFontStyle": "italic",
                                "titleScaleFontFactor": 0.3,
                                })) %>
        % endif

        <% txt.append(make_title("figure","summ_matrix_values", f"""Summary of embedding values 
                        before (A) and after (B) integration is presented. Both plots are segreggated by embedding
                         and x axis label points to {italic("individual graph source")} (A) or {italic("integration method")} (B).""")) %>
        ${collapsable_data("Embedding values Summary (click me)", "embd_values_summ", "\n".join(txt))}
</div>


















