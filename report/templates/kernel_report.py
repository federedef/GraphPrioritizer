<%
        import json 
        import re

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
                for process in processes:
                        tokens = process.split(" ")
                        if "get_similarity" in process:
                                # Ontology semantic
                                sim_type = extract_argument(tokens, "sim_type")
                                parsed_process = f"{sim_type.capitalize()} - Semantic Similarity"
                                parsed_processes += f"{parsed_process}"
                        elif "get_association_values" in process:
                                # Projections
                                if tokens[3] == "'correlation'":
                                        pvalue = extract_argument(tokens, "pvalue")
                                        corr_type = extract_argument(tokens, "corr_type")
                                        if corr_type == "": corr_type = "Pearson"

                                        parsed_process = f"{corr_type.capitalize()} Correlation<br>"
                                else:
                                        assoc = re.sub("'","",tokens[3])
                                        parsed_process = f"{assoc.capitalize()} Projection<br>"
                                parsed_processes += f"{parsed_process}"
                if parsed_processes == "":
                        # Raw
                        parsed_processes = "raw"

                return parsed_processes

        net2json = load_json("./net2json")
        annotations = net2json["data_process"]["layers2process"]

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
                                process = parse_process(info["Build_graph"])
                                edges.append((layer,process))
                                # process 2 filter
                                if info["Filter"] != []:
                                        filt = parse_filter(info["Filter"])
                                else:
                                        filt = "No filter"
                                edges.append((process, filt))
                                # filter 2 normalize
                                edges.append((filt, normalize_adj))
                                # normalize 2 embedding
                                for embedding in embeddings:
                                        edges.append((normalize_adj,embedding))
                                        edges.append((embedding,"Ranker"))
                                        phase2nodeid["embedding"].add(embedding)

                                phase2nodeid["database"].add(database)
                                phase2nodeid["layer"].add(layer)
                                phase2nodeid["process"].add(process)
                                phase2nodeid["filter"].add(filt)
                                phase2nodeid["normalize"].add(normalize_adj)

                                edges.append(("Seeds","Gene_candidates"))
                                edges.append(("Ranker","Gene_candidates"))
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
                edges.append(("Ranker","Gene_candidates"))
                return edges

        def edges2mermaid(edges, phase2nodeid = None):
                mermaid_edges = ""
                all_nodes = {}
                print("eyyyyyyyy")
                print(phase2nodeid)

                edges = list(set(edges))

                if phase2nodeid:
                        for node in phase2nodeid["database"]:
                                edges_in_phase = [ edge for edge in edges if edge[0] == node ]
                                mermaid_edges += f"  subgraph {node}_id[{node.upper()}]\n"
                                for edge in edges_in_phase:
                                        id1 = re.sub("_|-|,|\(|\)|\[|\]|<br>| ","_",edge[0])
                                        id2 = re.sub("_|-|,|\(|\)|\[|\]|<br>| ","_",edge[1])
                                        edge1 = " ".join([word.capitalize() for word in edge[0].split("_")])
                                        edge2 = " ".join([word.capitalize() for word in edge[1].split("_")])
                                        mermaid_edges += f"    {id1}[(\"{edge1}\")] --> {id2}(\"{edge2}\");\n"
                                mermaid_edges += f"  end\n"
                        edges = [edge for edge in edges if edge[0] not in phase2nodeid["database"]]
                for edge in edges:
                        id1 = re.sub("_|-|,|\(|\)|\[|\]|<br>| ","_",edge[0])
                        id2 = re.sub("_|-|,|\(|\)|\[|\]|<br>| ","_",edge[1])
                        edge1 = " ".join([word.capitalize() for word in edge[0].split("_")])
                        edge2 = " ".join([word.capitalize() for word in edge[1].split("_")])
                        mermaid_edges += f"  {id1}(\"{edge1}\") --> {id2}(\"{edge2}\");\n"

                mermaid_edges = mermaid_edges.replace("'","")
                return mermaid_edges

        def adding_href(mermaid_edges, nodes):
                mermaid_edges_with_href = mermaid_edges
                for node in nodes:
                        mermaid_edges_with_href += f"  click {node} href \"#{node}\";\n"
                return mermaid_edges_with_href




%>


<div style="width:90%; background-color:#FFFFFF; margin:50 auto; align-content: center;">

        <h1 style="text-align:center; background-color:#ecf0f1, color: powderblue; ">Analysis of the algorithm: From embeddings to prioritized genes.</h1>

        <p> The algorithm transformed the similarity matrix to make it compatible with the embedding process. Once this was done for each network and embedding type, it was integrated by embedding type. Below there is a general analysis of the properties of each matrix in the different phases of the process, including the graph building process for each layer. </p>

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue; text-decoration: underline;"> Annotation Properties </h3>

        <div style="overflow: hidden";>
                <p style="text-align:center;"><b>Table 1.</b> Annotation descriptors. </p> 
                <div style="overflow: hidden";>
                        % if plotter.hash_vars.get('parsed_annotations_metrics') is not None:
                                ${plotter.table(id='parsed_annotations_metrics', header=True,  text= True, row_names = True, fields= [0,5,4,6,8], styled='dt', border= 2, attrib = {
                                        'class' : "table table-striped table-dark"})}
                        % endif
                </div>
        </div>

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue; text-decoration: underline;"> Individual Processing Graph Flow </h3>
        <div>
        <%      
                edges, phase2nodeid = get_edge_non_integrated(net2json)
                edges=edges2mermaid(edges, phase2nodeid)
                edges=adding_href(edges, phase2nodeid["layer"])
                graph=f"""---\nTitle: Flux\nconfig:\n  theme: dark\n---\ngraph LR;\n{edges}"""
        %>
                ${ plotter.mermaid_chart(graph)}
        </div>

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue; text-decoration: underline;"> Individual Processing Graph Steps </h3>

            <%
                table = plotter.hash_vars["parsed_final_stats_by_steps"]
                ids = list(set([ row[1] for i,row in enumerate(table) if i > 0]))
                ids.sort()
                print(ids)
            %>

            % for elem in ids:
                <% key = "parsed_final_stats_by_steps_" + elem %>
                <% subtable = [row for i, row in enumerate(table) if i == 0 or row[1] == elem] %>
                <% plotter.hash_vars[key] = subtable %>
                <p style="text-align:center; font-size: 24px;" id="${re.sub('_sim','',elem)}"><b> ${parsed_string(elem)} </p>
                <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                ${plotter.barplot(id=key, fields= [2,6] , header= True, height= '400px', width= '400px', x_label= 'Density Element Not None', var_attr= [2],
                                        title = "Density matrix",
                                        config = {
                                                'showLegend' : True,
                                                'graphOrientation' : 'vertical',
                                                'colorBy' : 'Step',
                                                'setMinX': 0
                                                })}
                ${plotter.barplot(id=key, fields= [2,22] , header= True, height= '400px', width= '400px', x_label= 'Number of nodes', var_attr= [2],
                                        title = "Number of nodes",
                                        config = {
                                                'showLegend' : True,
                                                'graphOrientation' : 'vertical',
                                                'colorBy' : 'Step',
                                                'setMinX': 0
                                                })}
                ${plotter.line(id= key, fields= [0, 7, 19, 20, 21], header= True, row_names= True,
                                responsive= False,
                                height= '400px', width= '400px', x_label= 'Weight',
                                title= "Weight's similarity values",
                                config= {
                                        'showLegend' : True,
                                        'graphOrientation' : 'vertical',
                                        'colorBy' : 'Step'
                                        })}
                </div>
            % endfor
        
        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue; text-decoration: underline;"> Integration Graph Flow </h3>
        <div>
        <%
                edges=edges2mermaid(get_edge_integrated(net2json))
                graph=f"""---\nTitle: Flux\nconfig:\n  theme: dark\n---\ngraph LR;\n{edges}"""
        %>
                ${ plotter.mermaid_chart(graph)}
        </div>

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue; text-decoration: underline;"> Embedding Process </h3>

        <div style="overflow: hidden;">
                <p style="text-align:center;"><b>Table 2.</b> Uncombined Embedding Matrixes </p> 
                % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                                ${plotter.table(id='parsed_uncomb_kernel_metrics', text= True, header=True, row_names = True, fields= [1,2,3,4,5,6], styled='dt', cell_align= ['left', 'left', 'center', 'center', 'center', 'center'], border= 2,attrib= {
                                        'style' : 'margin-left: auto; margin-right:auto;',
                                        'cellspacing' : 0,
                                        'cellpadding' : 2})}
                % endif
                <p style="text-align:center;"><b>Table 3.</b> Integrated Embedding Matrixes </p>
                % if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                                ${plotter.table(id='parsed_comb_kernel_metrics', text= True, header=True, row_names = True, fields= [1,2,3,4,5,6], styled='dt', cell_align= ['left', 'left', 'center', 'center', 'center', 'center'], border= 2,attrib= {
                                        'style' : 'margin-left: auto; margin-right:auto;',
                                        'cellspacing' : 0,
                                        'cellpadding' : 2})}
                % endif

        </div>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                                ${ plotter.scatter2D(id= 'parsed_uncomb_kernel_metrics', title= "Size vs Density Matrix Uncombined", header= True, fields = [4,6], x_label = 'Size', y_label = 'Density', var_attr=[1,2], add_densities=True, alpha = 0.3,
                             config= {
                                'showLegend' : True,
                                "colorBy":"Net",
                                "shapeBy":"Kernel"
                                })}
                % endif
                % if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                                ${ plotter.scatter2D(id= 'parsed_comb_kernel_metrics', title= "Size vs Density Matrix Combined", header= True, fields = [4,6], x_label = 'Size', y_label = 'Density', var_attr=[1,2], add_densities=True, alpha = 0.3,
                             config= {
                                'showLegend' : True,
                                "colorBy":"Integration",
                                "shapeBy":"Kernel"
                                })}

                % endif
        </div>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                                ${plotter.barplot(id='parsed_uncomb_kernel_metrics', fields= [0,6] , header= True, height= '400px', width= '400px', x_label= 'Density Element Not None', var_attr= [1,2],
                                        title = "Density matrixes",
                                        config = {
                                                'showLegend' : True,
                                                'graphOrientation' : 'horizontal',
                                                'colorBy' : 'Kernel',
                                                "segregateSamplesBy": ["Net"],
                                                "axisTickScaleFontFactor": 0.2,
                                                'setMinX': 0
                                                })}
                % endif
                % if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                                ${plotter.barplot(id='parsed_comb_kernel_metrics', fields= [0,6] , header= True, height= '400px', width= '400px', x_label= 'Density Element Not None', var_attr= [1,2],
                                        title = "Density matrixes",
                                        config = {
                                                'showLegend' : True,
                                                'graphOrientation' : 'horizontal',
                                                'colorBy' : 'Kernel',
                                                'segregateSamplesBy': "Integration",
                                                'setMinX': 0
                                                })}
                % endif
        </div>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">

                % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                                ${plotter.line(id= "parsed_uncomb_kernel_metrics", fields= [0, 19, 20, 21], var_attr=[2], header= True, row_names= True,
                                responsive= False,
                                height= '400px', width= '400px', x_label= 'Embedding Value',
                                title= "Embedding values before integration",
                                config= {
                                        'showLegend' : True,
                                        'graphOrientation' : 'vertical',
                                        'segregateSamplesBy' : 'Kernel'
                                        })}
                % endif

                % if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                                ${plotter.line(id= "parsed_comb_kernel_metrics", fields= [2, 19, 20, 21], var_attr= [1], header= True, row_names= True,
                                responsive= False,
                                height= '400px', width= '400px', x_label= 'Embedding Value',
                                title= "Embedding values after integration",
                                config= {
                                        'showLegend' : True,
                                        'graphOrientation' : 'vertical',
                                        'segregateSamplesBy' : 'Integration'
                                        })}
                % endif
        </div>
</div>


















