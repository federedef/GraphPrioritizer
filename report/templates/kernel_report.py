<%
        import json 
        import re
        import py_exp_calc.exp_calc as pxc
        import sys
        sys.path.append("./report")
        import mermaid_parser as mp
        import pyreport_helper as ph

        parse_name = {"string_ppi_combined": "STRING combined", 
                "string_ppi_textmining":"STRING textmining",
                "string_ppi_coexpression": "STRING coexpression",
                "string_ppi_neighborhood": "STRING neighborhood",
                "string_ppi_experimental": "STRING experiments",
                "string_ppi_cooccurence": "STRING cooccurrence",
                "phenotype": "HPO",
                "disease":"Disease",
                "pathway": "Pathway",
                "DepMap_effect_pearson": "DepMap Pearson",
                "string_ppi_database":"STRING databases",
                "DepMap_effect_spearman":"DepMap Spearman",
                "hippie_ppi": "Hippie",
                "DepMap_Kim":"DepMap Kim",
                "string_ppi_fusion":"STRING fusion",
                "gene_hgncGroup": "HGNC group",
                "integration_mean_by_presence": "IMP",
                "mean": "Mean",
                "max": "Max",
                "median": "Median",
                "el": "EL",
                "raw_sim": "GSM",
                "node2vec": "node2vec",
                "rf": "RF"
                }

        if plotter.hash_vars.get('parsed_annotations_metrics') is not None:
                ph.order_columns(plotter,'parsed_annotations_metrics',0)
                ph.parse_table(plotter,'parsed_annotations_metrics', parse_name)

        if plotter.hash_vars.get('parsed_similarity_metrics') is not None:
                ph.order_columns(plotter,'parsed_similarity_metrics',0)
                ph.parse_table(plotter,'parsed_similarity_metrics', parse_name)

        if plotter.hash_vars.get('parsed_filtered_similarity_metrics') is not None:
                ph.order_columns(plotter,'parsed_filtered_similarity_metrics',0)
                ph.parse_table(plotter,'parsed_filtered_similarity_metrics', parse_name)

        if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                ph.order_columns(plotter,'parsed_uncomb_kernel_metrics',0)
                ph.parse_table(plotter,'parsed_uncomb_kernel_metrics', parse_name)

        if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                ph.order_columns(plotter,'parsed_comb_kernel_metrics',0)
                ph.parse_table(plotter,'parsed_comb_kernel_metrics', parse_name)
        
        plotter.hash_vars["density_heatmap_uncomb"] = ph.parse_heatmap_from_flat(plotter.hash_vars['parsed_uncomb_kernel_metrics'][1:],1,2,6,{22:"Size"},None,100)
        plotter.hash_vars["density_heatmap_comb"] = ph.parse_heatmap_from_flat(plotter.hash_vars['parsed_comb_kernel_metrics'][1:],1,2,6,{22:"Size"},None,100)
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
${ph.ul(lis)}
<% txt="Gene Relation Properties" %>
${plotter.create_title(txt, id='rel_prop', hlevel=2, indexable=True, clickable=False)}

<div style="overflow: hidden";>
        ${ph.make_title(plotter,"table", "annotation_descriptor", 
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
        net2json = mp.load_json("./net2json")
        annotations = net2json["data_process"]["layers2process"]
        subgraphs = {"normalize": "Adjacency Matrix <br> Normalization", "embedding": "Embedding", "control_embedding": "Control"}   
        custom_edges = { ("eGSM", "Ranker"):"-->",("Seeds","Ranker"):"-->"}
        custom_colours = {"Seeds": "#B7E4FF", "Ranker":"#FFA8A8"}
        edges, phase2nodeid = mp.get_edge_non_integrated(net2json) # Parse connections from json
        # building mermaid body
        # load nodes
        mermaid_body = mp.nodes2mermaid_by_phase(phase2nodeid, 
        {
        "database": {"name_parse": "upper", "node_type": "cylinder"},
        "layer":{"name_parse": "capitalize", "node_type": "round"},
        "process":{"name_parse": "capitalize", "node_type": "round"},
        "matrix_result": {"name_parse": "as_is", "node_type": "round"},
        "filter":{"name_parse": "capitalize", "node_type": "round"},
        "normalize":{"name_parse": "capitalize", "node_type": "round"},
        "embedding": {"name_parse": "capitalize", "node_type": "round"}
        })
        mermaid_body += mp.add_style_by_phase(phase2nodeid, {"process": "#BF7AE7","matrix_result": "#95B9F3"})
        # load edges
        mermaid_body += mp.edges2mermaid(mp.select_edges(edges, mp.select_nodes_from_classes(["layer","process","filter","matrix_result","normalize","embedding"], phase2nodeid)), "-->", "upper") 
        all_embeddings = {'el', 'node2vec', 'ka', 'rf', 'raw_sim'}
        phase2nodeid["embedding"] =  all_embeddings.intersection({'el', 'node2vec', 'ka', 'rf'})
        phase2nodeid["control_embedding"] = all_embeddings.intersection({'raw_sim'})
        mermaid_body += mp.get_subgraphs_for_neighbor(edges, phase2nodeid["database"]) # subgraph the neighboor
        mermaid_body += mp.phases2subpgrahs(phase2nodeid, subgraphs)
        mermaid_body += mp.adding_href(phase2nodeid["layer"])
        #mermaid_body += mp.adding_custom_edges(custom_edges, custom_colours, None, "as_is")
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
                "kim_coess_gene": "raw intersection",
                "DisparityFilter": "Disparity filter on graph"
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
        <% figure1= plotter.barplot(id=key, fields= [2,22] , header= True, height= '400px', width= '400px', x_label= 'Number of nodes', smp_attr= [2],
                                title = "(A) Network Size",
                                config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'vertical',
                                        'colorBy' : 'Step',
                                        'setMinX': 0,
                                        "smpLabelRotate": 90,
                                        "titleFontStyle": "italic",
                                        "titleScaleFontFactor": 0.7
                                        }) %>
        <% figure2 = plotter.barplot(id=key, fields= [2,6] , header= True, height= '400px', width= '400px', x_label= 'Density (%)', smp_attr= [2],
                                title = "(B) Network Density",
                                config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'vertical',
                                        'colorBy' : 'Step',
                                        'setMinX': 0,
                                        "smpLabelRotate": 90,
                                        "titleFontStyle": "italic",
                                        "titleScaleFontFactor": 0.7
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
                                "titleScaleFontFactor": 0.7
                                })%>
        <% text = f"""<p style="text-align:center;"><b> Figure {plotter.add_figure(key)} 
        </b> {ph.parsed_string(elem)} descriptive stats during network processing. Number of nodes (A), density (B) and summary of edge values (C) on the network. 
        Labels on x axis indicate diffente stages during the network building: {adding_text} </p>""" %>
        <% click_back="""<a href="#workflow_indv_layers">Back to Workflow</a>""" %>
        <%macro_txt = ph.collapsable_data(plotter,f"{ph.parsed_string(elem)}", re.sub('_sim','',elem), f"{elem}_container" ,"\n".join([f"<p id={re.sub('_sim','',elem)}></p>",figure1,figure2,figure3,text,click_back]))%>
        <% macro_click_txt.append(macro_txt) %>
    % endfor
    ${ph.collapsable_data(plotter,"All individual process summary", 'clickme_id'+"general", 'container'+"general","\n".join(macro_click_txt))}


<% txt="Selection and Integration of individual networks Workflow" %>
${plotter.create_title(txt, id="sel_int_workflow", hlevel=2, indexable=True, clickable=False)}
<div>
<%  

        {"integrated_layers": integrated_layers, "embeddings": embeddings, "integration_types": integration_types}
        phase2nodeid = mp.get_phase2nodeid_integrated(net2json)
        custom_edges = {
        ("integration_types_id","Integrated <br> eGSM"): "-->",
        ("embeddings_id","integration_types_id"): "-->", 
        ("integrated_layers_id","embeddings_id"): "-->"}      
        custom_colours = { "Integrated <br> eGSM": "#95B9F3"}
        subgraphs = {"integrated_layers": "Selected layers","embeddings": "Embeddings", "integration_types": "Integration"}   
        mermaid_body = mp.nodes2mermaid_by_phase(phase2nodeid, 
        {
        "integrated_layers": {"name_parse": "capitalize", "node_type": "round"},
        "embeddings":{"name_parse": "capitalize", "node_type": "round"},
        "integration_types":{"name_parse": "capitalize", "node_type": "round"}
        })
        mermaid_body += mp.phases2subpgrahs(phase2nodeid, subgraphs)
        mermaid_body += mp.adding_custom_edges(custom_edges, custom_colours, None, "as_is")
        graph=f"""---\nTitle: Flux\nconfig:\n  theme: base\n---\nflowchart TB;\n{mermaid_body}"""
%>
        ${ plotter.mermaid_chart(graph)}
        <% text=f""" Invididual raw and embedding networks were selected based on performance. Those 
        with the best predictive power were integrated all in one similarity matrix, based on 
        different integration methods ({ph.italic("Mean")}, {ph.italic("Max")}, {ph.italic("Integration Mean By Presence")}, {ph.italic("Median")}"""%>
        ${ph.make_title(plotter,"figure", "workflow_integration", text)}
</div>

<% txt="Embedding Process" %>
${plotter.create_title(txt, id="emb_process", hlevel=2, indexable=True, clickable=False)}



<div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                <div style="margin-right: 10px;">
                        % if plotter.hash_vars.get('density_heatmap_uncomb') is not None:
                                ${ plotter.heatmap(id = 'density_heatmap_uncomb', title="",header = True, row_names = True, smp_attr=[1],
                                        config= {
                                        "varTextRotate":45,
                                        "smpOverlays":["Size"],
                                        "smpOverlayProperties": {"Size":{"type":"Bar","thickness":200,"color":"Black"}},
                                        "setMinX":0,
                                        "setMaxX":1, 
                                        "xAxisTitle": "Density", 
                                        "samplesClustered":True,
                                        "showSmpDendrogram":False}) }
                        % endif
                </div>
                <div style="margin-left: 10px;"> 
                        % if plotter.hash_vars.get('density_heatmap_comb') is not None: 
                                ${ plotter.heatmap(id = 'density_heatmap_comb', header = True, title="", row_names = True, smp_attr=[1],
                                        config= {
                                        "smpOverlays":["Size"],
                                        "smpOverlayProperties": {"Size":{"type":"Bar","thickness":30,"color":"Black"}},
                                        "setMinX":0,
                                        "setMaxX":1, 
                                        "xAxisTitle": "Density", 
                                        "samplesClustered":True,
                                        "showSmpDendrogram":False}) }
                        % endif
                </div>
        </div>

        ${ph.make_title(plotter,"figure","density_summ", f"""Summary of eGSM density (%) before (A) and after (B) integration.
        Both plots are segreggated by {ph.italic("individual graph source")} (A) or {ph.italic("integration method")} (B), coloured by embedding process.""")}
</div>

<% txt = [] %>
% if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
        <% txt.append(ph.make_title(plotter,"table", "unc_emb_matrix",
                f"""Summary metrics for each eGSM obtained by every source and embedding. Showing metrics on size
                ({ph.italic("Matrix Dimensions")}, {ph.italic("Matrix Elements")}) and density 
                ({ph.italic("Matrix Elements Non Zero")}, {ph.italic("Matrix non zero density")}) matrix.""")) %>
        <% txt.append(plotter.table(id='parsed_uncomb_kernel_metrics', text= True, header=True, row_names = True, fields= [1,2,3,4,5,6], styled='dt', cell_align= ['left', 'left', 'center', 'center', 'center', 'center'], border= 2,attrib= {
                        'class': 'table table-striped table-hover',
                        'cellspacing' : 0,
                        'cellpadding' : 2})) %>
        ${ph.collapsable_data(plotter,"Individual eGSM Matrix Sumary", None, "individual_egsm_matrix_summ", "\n".join(txt))}
% endif
% if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
        <% txt = [] %>
        <% txt.append(ph.make_title(plotter,"table", "c_emb_matrix",
                f"""Summary metrics for each eGSM obtained after integration step. Showing metrics on size
                ({ph.italic("Matrix Dimensions")}, {ph.italic("Matrix Elements")}) and density 
                ({ph.italic("Matrix Elements Non Zero")}, {ph.italic("Matrix non zero density")}) matrix."""))%>
        <% txt.append(plotter.table(id='parsed_comb_kernel_metrics', text= True, header=True, row_names = True, fields= [1,2,3,4,5,6], styled='dt', cell_align= ['left', 'left', 'center', 'center', 'center', 'center'], border= 2,attrib= {
                        'class': 'table table-striped',
                        'cellspacing' : 0,
                        'cellpadding' : 2})) %>
        ${ph.collapsable_data(plotter,"Integrated eGSM Matrix Sumary", None, "integrated_egsm_matrix_summ", "\n".join(txt))}
% endif

% if plotter.hash_vars.get("parsed_graph_attr_by_net"):
        ${plotter.scatter3D(id= 'parsed_graph_attr_by_net', header= True, row_names = True, x_label = "Edge density (%)", y_label = 'Transitivity', z_label= "Assorciativity",
                                                var_attr=[1], xAxis = "edge_density", yAxis="transitivity", zAxis="assorciativity", pointSize="size")}
% endif

% if plotter.hash_vars.get('parsed_graph_attr_by_net') is not None:

                <%      
                        get_name = {"string_ppi_combined_sim": "String-comb", "string_ppi_textmining_sim":"String-text",
                         "string_ppi_coexpression_sim": "String-coex",
                         "string_ppi_neighborhood_sim": "String-neighb",
                         "string_ppi_experimental_sim": "String-exp",
                         "string_ppi_cooccurence_sim": "string-coo",
                         "phenotype_sim": "Phen",
                         "disease_sim":"Dis",
                         "pathway_sim": "Path",
                         "DepMap_effect_pearson_sim": "DepMap-P",
                         "string_ppi_database_sim":"String-dbs",
                         "DepMap_effect_spearman_sim":"DepMap-S",
                         "hippie_ppi_sim": "Hippie",
                         "DepMap_Kim_sim":"DepMap-K",
                         "string_ppi_fusion_sim":"String-fus",
                         "gene_hgncGroup_sim": "HGNC-group"
                         }
                        for i, row in enumerate(plotter.hash_vars['parsed_graph_attr_by_net']):
                                if i != 0: 
                                        row[0] = get_name[row[0]]


                %>
                ${plotter.scatter2D(id= 'parsed_graph_attr_by_net', title= "Network topology", header= True, row_names = True, fields = [0,4,3], x_label = 'Assorciativity', y_label = 'transitivity', smp_attr=[1,2], alpha = 0.3, 
                config= {
                'showLegend' : True,
                "colorBy":"edge_density",
                "sizeBy":"size",
                "titleFontStyle": "italic",
                "titleScaleFontFactor": 0.7,
                "dataTextFontStyle": "bold italic",
                "showDataLabels": True,
                "dataTextScaleFontFactor":0.65,
                "setMaxX": 1,
                "jitter": True,
                "jitterFactor": 0.05,
                "dataTextAlign": "center",
                "dataTextRotate": 0,
                "dataTextBaseline": "bottom"




                })}

% endif

<% txt = [] %>
% if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                <% txt.append(plotter.scatter2D(id= 'parsed_uncomb_kernel_metrics', title= "(A) Size vs Density on eGSM", header= True, fields = [4,6], x_label = 'Number of posible relations', y_label = 'Matriz Non Zero Density', smp_attr=[1,2], alpha = 0.3,
                config= {
                'showLegend' : True,
                "colorBy":"Net",
                "segregateVariablesBy":"Embedding",
                "titleFontStyle": "italic",
                "titleScaleFontFactor": 0.7,
                })) %>
% endif

% if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                <% txt.append(plotter.scatter2D(id= 'parsed_comb_kernel_metrics', title= "(B) Size vs Density on eGSM", header= True, fields = [4,6], x_label = 'Number of posible relations', y_label = 'Matrix Non Zero Density', smp_attr=[1,2], alpha = 0.3,
                config= {
                'showLegend' : True,
                "colorBy":"Integration",
                "segregateVariablesBy":"Embedding",
                "titleFontStyle": "italic",
                "titleScaleFontFactor": 0.7,
                })) %>

% endif
<%txt.append(ph.make_title(plotter,"figure", "figure_sizeVSdensity", "Size vs Density on eGSM before (A) and after (B) integration step, respectively.  The plots are categorised according to the embedding methods used, with colours representing individual graphs in (A) or integration methods in (B)."))%>
${ph.collapsable_data(plotter,"Density vs Size", None, "dens_size", "\n".join(txt))}


<% txt = [] %>
% if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                <% txt.append(plotter.line(id= "parsed_uncomb_kernel_metrics", fields= [1, 19, 20, 21], smp_attr=[2], header= True, row_names= True,
                responsive= False,
                height= '400px', width= '400px', x_label= 'Embedding \n Values',
                title= "(A) Embedding values \nbefore integration",
                config= {
                        'showLegend' : True,
                        'graphOrientation' : 'vertical',
                        'segregateSamplesBy' : 'Embedding',
                        "smpLabelRotate": 45,
                        "titleFontStyle": "italic",
                        "titleScaleFontFactor": 0.7
                        }))%>
% endif
% if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                <% txt.append(plotter.line(id= "parsed_comb_kernel_metrics", fields= [1, 19, 20, 21], smp_attr= [2], header= True, row_names= True,
                responsive= False,      
                height= '400px', width= '400px', x_label= 'Embedding \n Values',
                title= "(B) Embedding values \nafter integration",
                config= {
                        'showLegend' : True,
                        'graphOrientation' : 'vertical',
                        'segregateSamplesBy' : 'Embedding',
                        "smpLabelRotate": 45,
                        "titleFontStyle": "italic",
                        "titleScaleFontFactor": 0.7
                        })) %>
% endif

<% txt.append(ph.make_title(plotter,"figure","summ_matrix_values", f"""Summary of eGSM values 
                before (A) and after (B) integration. Both plots are segreggated by embedding type
                 and x axis label points to {ph.italic("individual graph source")} (A) or {ph.italic("integration method")} (B).""")) %>
${ph.collapsable_data(plotter,"Embedding values Summary", None, "embd_values_summ", "\n".join(txt))}