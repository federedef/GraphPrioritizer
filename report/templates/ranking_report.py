<%
        import os.path
        import warnings
        import pandas as pd
        import re
        import py_exp_calc.exp_calc as pxc
        import sys
        sys.path.append("./report")
        import pyreport_helper as ph
        warnings.simplefilter(action='ignore', category=FutureWarning)

        # Defining variables 
        #####################
        number_of_positives = len(plotter.hash_vars["control_pos"]) -1
        
        # Text
        #######

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
                "rf": "RF",
                "auc_down_ci_0.95": "AUROC-0.025",
                "auc_up_ci_0.95": "AUROC-0.975",
                "auc": "AUROC"
                }

        # Parse tables
        ##############

        def get_medianrank_size(var_name, groupby = ['annot_Embedding','annot','Embedding','group_seed'], value = 'rank'):
                df = pd.DataFrame(plotter.hash_vars[var_name][1:], columns = plotter.hash_vars[var_name][0])
                median_by_attributes = df.groupby(groupby)[value].median().reset_index()
                len_by_attributes = df.groupby(groupby)[value].size().reset_index()
                concatenated_df = pd.concat([median_by_attributes, len_by_attributes[[value]]], axis=1)
                col_names = plotter.hash_vars[var_name][0]
                col_names.append("size")
                return [col_names] + concatenated_df.values.tolist()

        def get_size(var_name, groupby = ['annot_Embedding','annot','Embedding','group_seed'], value = 'rank'):
                df = pd.DataFrame(plotter.hash_vars[var_name][1:], columns = plotter.hash_vars[var_name][0])
                len_by_attributes = df.groupby(groupby)[value].size().reset_index()
                len_by_attributes = len_by_attributes.sort_values(by=value)
                col_names = plotter.hash_vars[var_name][0]
                return [col_names] + len_by_attributes.values.tolist()

%>
<%
        # Parsing tables
        ################

        for table in plotter.hash_vars.keys():
                if table == "parsed_non_integrated_rank_summary" or table == "parsed_integrated_rank_summary":
                        ph.parse_table(plotter, table, parse_name, include_header=True)
                else:
                        ph.parse_table(plotter, table, parse_name)

        if plotter.hash_vars.get('parsed_non_integrated_rank_summary') is not None:
                ph.order_columns(plotter,'parsed_non_integrated_rank_summary',0)

        if plotter.hash_vars.get('parsed_integrated_rank_summary') is not None:
                ph.order_columns(plotter,'parsed_integrated_rank_summary',0)

        if plotter.hash_vars.get('parsed_non_integrated_rank_pos_cov') is not None:
                ph.order_columns(plotter,'parsed_non_integrated_rank_pos_cov',0)
                plotter.hash_vars["parsed_non_integrated_rank_pos_cov"] = ph.modify_by_cols(plotter,"parsed_non_integrated_rank_pos_cov", [3], lambda x: float(x)/number_of_positives * 100)
                plotter.hash_vars['parsed_non_integrated_rank_pos_cov'] = ph.parse_heatmap_from_flat(plotter.hash_vars['parsed_non_integrated_rank_pos_cov'][1:],1,2,3,None,None)

        if plotter.hash_vars.get('parsed_integrated_rank_pos_cov') is not None:
                ph.order_columns(plotter,'parsed_integrated_rank_pos_cov',0)
                plotter.hash_vars["parsed_integrated_rank_pos_cov"] = ph.modify_by_cols(plotter,"parsed_integrated_rank_pos_cov", [3], lambda x: float(x)/number_of_positives * 100)
                plotter.hash_vars['parsed_integrated_rank_pos_cov'] = ph.parse_heatmap_from_flat(plotter.hash_vars['parsed_integrated_rank_pos_cov'][1:],1,2,3,None,None)
           
        if plotter.hash_vars.get('parsed_annotation_grade_metrics') is not None:
                ph.order_columns(plotter,'parsed_annotation_grade_metrics',0)

        if plotter.hash_vars.get('non_integrated_rank_group_vs_posrank') is not None:
                plotter.hash_vars["non_integrated_rank_group_vs_posrank"] = get_medianrank_size('non_integrated_rank_group_vs_posrank', groupby = ['annot_Embedding','annot','Embedding','group_seed'], value = 'rank')
        if plotter.hash_vars.get('integrated_rank_group_vs_posrank') is not None:
                plotter.hash_vars["integrated_rank_group_vs_posrank"] = get_medianrank_size('integrated_rank_group_vs_posrank', groupby = ['integration_Embedding','integration','Embedding','group_seed'], value = 'rank')
        if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group'):
                plotter.hash_vars['non_integrated_rank_medianauc'] = get_medianrank_size('non_integrated_rank_size_auc_by_group', groupby = ["sample","annot","Embedding","seed","pos_cov"], value = 'auc')
        if plotter.hash_vars.get('integrated_rank_size_auc_by_group'):
                plotter.hash_vars["integrated_rank_medianauc"] = get_medianrank_size("integrated_rank_size_auc_by_group", groupby = ["sample","method","Embedding","seed","pos_cov"], value = 'auc')

        if plotter.hash_vars.get("control_pos") is not None:
                plotter.hash_vars["seed_size"] = get_size("control_pos", groupby=["Seed Name"], value = "Genes")

        bench_type = ""
        if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group') is not None:
                bench_type = "menche"
        else:
                bench_type = "zampieri"

%>
<% plotter.set_header() %>
<% txt="From Graph Embeddings to Gene Candidates." %>
${plotter.create_title(txt, id='main_title', hlevel=1, indexable=True, clickable=False)}
<p>
The eGSMs, both individual and integrated, are used in conjunction with the ranker prioritisation algorithm.
This report presents coverage metrics, cumulative density, and ROC curves.
</p>

<% txt="Workflow of benchmarking process" %>
${plotter.create_title(txt, id='workflow_bench', hlevel=2, indexable=True, clickable=False)}
% if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group') is not None: 
        <div>
                <%
                        graph=f"""
                        graph LR
                        Database[(<span style="color:#21002E">OrphaNet</span>)]
                        Seeds[<span style="color:#21002E"><b>Seeds</b><br>G1<br>G2<br>G3<br>...<br>Gn</span>]
                        Seed{{{{<span style="color:#263285">Gi</span>}}}}
                        Input><span style="color:#263285"><b>Input</b></span>]
                        It1[Iteration 1]
                        It2[Iteraction 2]
                        Iti[...]
                        Itn[Iteration 10]
                        N[<span style="color:#500000">Negative</span>]
                        P[<span style="color:#023020">Positive</span>]
                        ROC[<span style="color:#000000">ROC</span>]
                        cdf[<span style="color:#000000">CDF</span>]
                        Coverage[<span style="color:#000000">Coverage</span>]
                        eGSM_ind{{{{<span style="color:#263285">eGSM</span>}}}}
                        Database --get groups <br> n&ge;20--> Seeds
                        Seed --> Input
                        eGSM_ind --> Input
                        Seeds --Iterate by <br> seed--> Seed
                        subgraph Iterations [<b>Ranker</b> <br> <u><i>10-fold CV</i></u>]
                        It1
                        It2
                        Iti
                        Itn    
                        end
                        subgraph p_metrics [<b><u>Performance  metrics</b></u>]
                        N 
                        P 
                        ROC 
                        cdf
                        Coverage
                        end
                        Input --> It1
                        Input --> It2
                        Input --> Iti
                        Input --> Itn
                        Iterations --> P
                        Iterations --> N
                        N --> ROC
                        P --> ROC
                        P --> cdf
                        P --> Coverage
                        style P fill:#C0EAB9,stroke:#0D3E05,stroke-width:3px
                        style N fill:#FF8C80,stroke:#8C1F14,stroke-width:3px
                        style cdf fill:#A0A0A0,stroke:#333,stroke-width:2px
                        style ROC fill:#A0A0A0,stroke:#333,stroke-width:2px
                        style Coverage fill:#A0A0A0,stroke:#333,stroke-width:2px
                        style Database fill:#D089ED ,stroke:#333,stroke-width:2px
                        style Seeds fill:#D089ED ,stroke:#333,stroke-width:2px
                        style Seed fill:#D9E7FF,stroke:#263285,stroke-width:2px
                        style eGSM_ind fill:#D9E7FF,stroke:#263285,stroke-width:2px
                        style Input fill:#D9E7FF,stroke:#263285,stroke-width:2px
                        style Iterations stroke:#333,stroke-width:2px,text-align:center
                        style p_metrics fill:#F3F3F3,stroke:#333,stroke-width:2px,text-align:center
                        style It1 fill:#F5F5F5,stroke:#333,stroke-width:2px
                        style It2 fill:#F5F5F5,stroke:#333,stroke-width:2px
                        style Iti fill:#F5F5F5,stroke:#333,stroke-width:2px
                        style Itn fill:#F5F5F5,stroke:#333,stroke-width:2px
                        """
                %>
                ${plotter.mermaid_chart(graph)}
        </div>
        ${ph.make_title(plotter,"figure", "seed_wflow", """Workflow of the benchmarking process. Seeds are obtained from Orphanet disease genes agglomeration with n &ge; 20.
         Then, a 10-fold CV is performed for each seed, obtaining positives and using genome background as negatives.""")}    
% else:
        <div>
                <%
                        graph=f"""
                        graph LR
                        Database[(<span style="color:#21002E">OMIM</span>)]
                        Seeds[<span style="color:#21002E"><b>Seeds</b><br>G1<br>G2<br>G3<br>...<br>Gn</span>]
                        Seed{{{{<span style="color:#263285">Gi</span>}}}}
                        Input><span style="color:#263285"><b>Input</b></span>]
                        It1[LOO-1]
                        It2[LOO-2]
                        Iti[...]
                        Itn[LOO-n]
                        N[<span style="color:#500000">Negative</span>]
                        P[<span style="color:#023020">Positive</span>]
                        ROC[<span style="color:#000000">ROC</span>]
                        cdf[<span style="color:#000000">CDF</span>]
                        Coverage[<span style="color:#000000">Coverage</span>]
                        eGSM_ind{{{{<span style="color:#263285">eGSM</span>}}}}
                        Database --get groups <br> n&ge;30--> Seeds
                        Seed --> Input
                        eGSM_ind --> Input
                        Seeds --Iterate by <br> seed--> Seed
                        subgraph Iterations [<b>Ranker</b> <br> <u><i>Leave One Out</i></u>]
                        It1
                        It2
                        Iti
                        Itn    
                        end
                        subgraph p_metrics [<b><u>Performance  metrics</b></u>]
                        N 
                        P 
                        ROC 
                        cdf
                        Coverage
                        end
                        Input --> It1
                        Input --> It2
                        Input --> Iti
                        Input --> Itn
                        Iterations --> P
                        Iterations --> N
                        N --> ROC
                        P --> ROC
                        P --> cdf
                        P --> Coverage
                        style P fill:#C0EAB9,stroke:#0D3E05,stroke-width:3px
                        style N fill:#FF8C80,stroke:#8C1F14,stroke-width:3px
                        style cdf fill:#A0A0A0,stroke:#333,stroke-width:2px
                        style ROC fill:#A0A0A0,stroke:#333,stroke-width:2px
                        style Coverage fill:#A0A0A0,stroke:#333,stroke-width:2px
                        style Database fill:#D089ED ,stroke:#333,stroke-width:2px
                        style Seeds fill:#D089ED ,stroke:#333,stroke-width:2px
                        style Seed fill:#D9E7FF,stroke:#263285,stroke-width:2px
                        style eGSM_ind fill:#D9E7FF,stroke:#263285,stroke-width:2px
                        style Input fill:#D9E7FF,stroke:#263285,stroke-width:2px
                        style Iterations stroke:#333,stroke-width:2px,text-align:center
                        style p_metrics fill:#F3F3F3,stroke:#333,stroke-width:2px,text-align:center
                        style It1 fill:#F5F5F5,stroke:#333,stroke-width:2px
                        style It2 fill:#F5F5F5,stroke:#333,stroke-width:2px
                        style Iti fill:#F5F5F5,stroke:#333,stroke-width:2px
                        style Itn fill:#F5F5F5,stroke:#333,stroke-width:2px
                        """
                %>
                ${ plotter.mermaid_chart(graph)}
        </div>
        ${ph.make_title(plotter,"figure", "seed_wflow", """Workflow of the benchmarking process. Seeds are obatined from OMIM disease genes agglomeration with n &ge; 30.
         Then, leave one out is performed for each seed, obtaining positives and using genes in others seeds as negatives.""")}    
% endif


<% txt="Seed Size" %>
${plotter.create_title(txt, id='seed_size', hlevel=2, indexable=True, clickable=False)}
<div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
        % if plotter.hash_vars.get('control_pos') is not None:
                        ${plotter.barplot(id='seed_size', fields= [0,1] , colorScale=True, header= True, height= '400px', width= '400px', x_label= 'Number of genes by seed', title= "", config={"maxSmpStringLen": 60})}
        % endif
</div>


<% txt="Genes Coverage" %>
${plotter.create_title(txt, id='pos_cov', hlevel=2, indexable=True, clickable=False)}

<div style="overflow: hidden";>
        <div style="overflow: hidden";>
                % if plotter.hash_vars.get('control_pos') is not None:
                        <% txt = [ph.make_title(plotter,"table","table_seedgroups", "Seed groups.")] %>
                        <% txt.append(plotter.table(id='control_pos', header=True,  text= True, row_names = True, fields= [0,1], styled='dt', border= 2, attrib = {
                                'class' : "table table-striped table-dark"}))%>
                        ${ph.collapsable_data(plotter,"Positive control", None, "positive_control_table", "\n".join(txt))}
                % endif

        </div>
</div>


<div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
        <div style="margin-right: 10px;">
                % if plotter.hash_vars.get('parsed_non_integrated_rank_pos_cov') is not None:
                        ${ plotter.heatmap(id = 'parsed_non_integrated_rank_pos_cov', title="",header = True, row_names = True, 
                                config= {"setMinX":0,
                                "setMaxX":100, 
                                "xAxisTitle": "Coverage", 
                                "samplesClustered":True,
                                "showSmpDendrogram":False}) }
                % endif
        </div>
        <div style="margin-left: 10px;"> 
                % if plotter.hash_vars.get('parsed_integrated_rank_pos_cov') is not None: 
                        ${ plotter.heatmap(id = 'parsed_integrated_rank_pos_cov', header = True, title="", row_names = True, 
                                config= {"setMinX":0,
                                "setMaxX":100, 
                                "xAxisTitle": "Coverage", 
                                "samplesClustered":True,
                                "showSmpDendrogram":False}) }
                % endif
        </div>
</div>
${ph.make_title(plotter,"figure", "coverage_bars", """Coverage obtained in each individual (A)
 or integrated (B) eGSM. In both plots, x axis reflects the number of positive control genes with information on the adjacency matrix, 
 with zero or minimum value on edges for the corresponding seed.""")}

<% txt="General Performance Metrics" %>
${plotter.create_title(txt, id='gen_per_metrics', hlevel=2, indexable=True, clickable=False)}

<% txt="Summary Distribution of Performance Metrics" %>
${plotter.create_title(txt, id='sum_gen_per_metrics', hlevel=3, indexable=True, clickable=False)}

<%
txt = []
if plotter.hash_vars.get('non_integrated_rank_cdf') is not None: 
        txt.append(plotter.boxplot(id= 'non_integrated_rank_cdf', header= True, row_names= False, default= False, fields= [5],  smp_attr= [0,1,2], group = "Embedding",
           title= "(A) Individual eGSM",
                x_label= "Normalized rank",
                config= {
                        'showLegend' : True,
                        "graphOrientation": "vertical",
                        "colorBy" : "Embedding",
                        "groupingFactors" :
                        ["Embedding"],
                        "titleFontStyle": "italic",
                        "titleScaleFontFactor": 0.7,
                        "segregateSamplesBy": "annot"}))
if plotter.hash_vars.get('integrated_rank_cdf') is not None: 
        txt.append(plotter.boxplot(id= 'integrated_rank_cdf', header= True, row_names= False, default= False, fields = [5], smp_attr= [0,1,2], group= "Embedding", 
                title= "(B) Integrated eGSM",
                xlabel= "Normalized rank",
                config= {
                        'showLegend' : True,
                        "graphOrientation": "vertical",
                        "colorBy" : "Embedding",
                        "xAxisTitle": "Normalized rank",
                        "groupingFactors" :
                        ["Embedding"],
                        "titleFontStyle": "italic",
                        "titleScaleFontFactor": 0.7,
                        "segregateSamplesBy": "integration"}))
txt.append(ph.make_title(plotter,"figure", "rank_boxplot", f"""Rank distributions in each individual (A)
 or integrated (B) eGSM. In both plots, y axis ({ph.italic("Normalized ranks")}) represent the rank normalized on 0-1 range."""))
%>
${ph.collapsable_data(plotter,"Normalized Rank Boxplot", "norm_rank_click", "norm_rank_collaps","\n".join(txt))}

<div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
        <div style="margin-right: 10px;">
                         % if plotter.hash_vars.get('non_integrated_rank_medianauc') is not None: 
                                ${plotter.boxplot(id= 'non_integrated_rank_medianauc', header= True, row_names= False, default= False, fields= [5],  smp_attr= [0,1,2,3], group = ["Embedding"],
                                   title= "(A) Individual eGSM",
                                        x_label= "median AUROC",
                                        config= {
                                                'showLegend' : True,
                                                "graphOrientation": "vertical",
                                                "colorBy" : "Embedding",
                                                "groupingFactors" :
                                                ["Embedding"],
                                                "segregateSamplesBy": "annot",
                                                "jitter": True,
                                                "showBoxplotIfViolin": True,
                                                "showBoxplotOriginalData": True,
                                                "showViolinBoxplot":True,
                                                "titleFontStyle": "italic",
                                                "titleScaleFontFactor": 0.7,
                                                "setMinX": 0,
                                                "fontScaleFontFactor": 1.5,
                                                "axisTitleScaleFontFactor": 1.5,
                                                "axisTickScaleFontFactor": 1.5,
                                                "legendTextScaleFontFactor": 1.2,
                                                "legendTitleScaleFontFactor": 1.4})}
                        % endif
        </div>
        <div style="margin-left: 10px;">
                         % if plotter.hash_vars.get('integrated_rank_medianauc') is not None: 
                                ${plotter.boxplot(id= 'integrated_rank_medianauc', header= True, row_names= False, default= False, fields= [5],  smp_attr= [0,1,2], group = ["Embedding"],
                                   title= "(B) Integrated eGSM",
                                        x_label= "median AUROC",
                                        config= {
                                                'showLegend' : True,
                                                "graphOrientation": "vertical",
                                                "colorBy" : "Embedding",
                                                "groupingFactors" :
                                                ["Embedding"],
                                                "segregateSamplesBy": "method",
                                                "jitter": True,
                                                "showBoxplotIfViolin": True,
                                                "showBoxplotOriginalData": True,
                                                "showViolinBoxplot": True,
                                                "titleFontStyle": "italic",
                                                "titleScaleFontFactor": 0.7,
                                                "smpTextRotate": 45,
                                                "setMinX": 0,
                                                "fontScaleFontFactor": 1.5,
                                                "axisTitleScaleFontFactor": 1.5,
                                                "axisTickScaleFontFactor": 1.5,
                                                "legendTextScaleFontFactor": 1.2,
                                                "legendTitleScaleFontFactor": 1.4})}
                        % endif
        </div>
</div>
% if bench_type == "menche":
        ${ph.make_title(plotter,"figure", "roc_boxplot", f"""Median AUROC distributions in each individual (A)
 or integrated (B) eGSM. In both plots, y axis ({ph.italic("median AUROCs")}) represent the median of the 10-fold-CV AUROCs for each seed.""")}
% endif

<% txt="Curve Distribution of Performance Metrics" %>
${plotter.create_title(txt, id='curv_gen_per_metrics', hlevel=3, indexable=True, clickable=False)}

<%
txt = []
if plotter.hash_vars.get("non_integrated_rank_cdf") is not None: 
        txt.append(plotter.static_plot_main( id="non_integrated_rank_cdf", header=True, row_names=False, smp_attr=[0,1,2,3], fields =[4,5,6],
                        plotting_function= lambda data, plotter_list: ph.plot_with_facet(plot_type="ecdf",data=data, 
                                plotter_list=plotter_list, x="rank", col="annot", 
                                hue="Embedding", col_wrap=3, 
                                suptitle="A", x_label="Normalized Rank", y_label="TPR", top=0.9)))
if plotter.hash_vars.get("integrated_rank_cdf") is not None: 
        txt.append(plotter.static_plot_main( id="integrated_rank_cdf", header=True, row_names=False, smp_attr=[0,1,2,3], fields =[4,5,6],
                        plotting_function= lambda data, plotter_list: ph.plot_with_facet(plot_type="ecdf",data=data, plotter_list=plotter_list, x="rank", 
                                col="integration", hue="Embedding", col_wrap=2, suptitle="B", x_label="Normalized Rank", y_label="TPR", top=0.8)))
txt.append(ph.make_title(plotter,"figure", "cdf_curve", f"""CDF curves by each individual (A)
 or integrated (B) eGSM. In both plots, y axis represent 
 the true positive rate ({ph.italic("TPR")}) and x axis ({ph.italic("Normalized Rank")}) the rank normalized from 0 to 1."""))
txt.append("""<a href="https://academic.oup.com/bib/article/23/2/bbac019/6521702#330302198"> Xiao Yuan et al. Evaluation of
 phenotype-driven gene prioritization methods for Mendelian diseases, Briefings in Bioinformatics, Volume 23, Issue 2, March 2022, bbac019 </a>""")
%>
${ph.collapsable_data(plotter,"CDF Curves", "cdf_click", "cdf_collaps","\n".join(txt))}


<%
txt = []
if plotter.hash_vars.get("non_integrated_rank_measures") is not None: 
        txt.append(plotter.static_plot_main( id="non_integrated_rank_measures", header=True, row_names=False, smp_attr=[0,1,2,3], fields =[4,5,6],
                                plotting_function= lambda data, plotter_list: ph.plot_with_facet(plot_type="lineplot", data=data,
                                        plotter_list=plotter_list, x='fpr', y='tpr', col='annot', 
                                        hue='Embedding', col_wrap=3, suptitle="A", 
                                        top=0.9, x_label="FPR", y_label="TPR")))

if plotter.hash_vars.get("integrated_rank_measures") is not None: 
        txt.append(plotter.static_plot_main( id="integrated_rank_measures", header=True, row_names=False, smp_attr=[0,1,2,3], fields =[4,5,6], 
                                plotting_function= lambda data, plotter_list: ph.plot_with_facet(plot_type="lineplot",data=data, 
                                        plotter_list=plotter_list, x='fpr', y='tpr', col='integration', 
                                        hue='Embedding', col_wrap=2, suptitle="B", 
                                        top=0.8, labels = 'Embedding', x_label="FPR", y_label="TPR")))
txt.append(ph.make_title(plotter,"figure", "roc_curve", f"""ROC curve by each individual (A) or integrated (B) eGSM."""))
%>
% if bench_type == "menche":
        ${ph.collapsable_data(plotter,"ROC Curves", "roc_curves_click", "roc_curves_collaps","\n".join(txt))}
% else:
        ${"\n".join(txt)}
% endif


<% txt = [] %>
% if plotter.hash_vars.get("parsed_non_integrated_rank_summary") is not None: 
        <% txt.append(plotter.line(id= "parsed_non_integrated_rank_summary", fields= [1, 7, 13, 8], header= True, row_names= True, smp_attr=[0,2],
                responsive= False,
                height= '400px', width= '400px', x_label= 'AUROC',
                title= "(A) Individual eGSM",
                config= {
                        'showLegend' : True,
                        'graphOrientation' : 'vertical',
                        "titleFontStyle": "italic",
                        "titleScaleFontFactor": 0.7,
                        'setMinX': 0,
                        'setMaxX': 1,
                        "smpTextRotate": 45,
                        "segregateSamplesBy": "Embedding"
                        })) %>
% endif
% if plotter.hash_vars.get('parsed_integrated_rank_summary') is not None: 
        <% txt.append(plotter.line(id= "parsed_integrated_rank_summary", fields=  [2, 7, 13, 8], header= True, row_names= True, smp_attr = [0,1],
                responsive= False,
                height= '400px', width= '400px', x_label= 'AUROC',
                title= "(B) Integrated eGSM",
                config= {
                        'showLegend' : True,
                        'graphOrientation' : 'vertical',
                        "titleFontStyle": "italic",
                        "titleScaleFontFactor": 0.7,
                        'setMinX': 0,
                        'setMaxX': 1,
                        "smpTextRotate": 45,
                        "segregateSamplesBy": "Integration"
                        })) %>
% endif
<% txt.append(ph.make_title(plotter,"figure", "roc_ic", f"""AUROC Confidence Interval (CI) in each individual (A) or integrated (B) eGSM. CI was obtained by a 1000 iteration bootstrap.""")) %>
${ph.collapsable_data(plotter,"AUROC Condifence Intervals", "auroc_ci_click", "auroc_ci_collaps","\n".join(txt))}


% if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group') is not None: 

        <% txt="Performance by seed" %>
        ${plotter.create_title(txt, id='perf_by_seed', hlevel=2, indexable=True, clickable=False)}
        <%
                table = plotter.hash_vars["non_integrated_rank_size_auc_by_group"]
                ids = list(set([ row[1] for i,row in enumerate(table) if i > 0]))
                ids.sort()
        %>
        <% macro_click_txt = [] %>
        % for elem in ids:
                <% key = "non_integrated_rank_size_auc_by_group" + elem %>
                <% subtable = [row for i, row in enumerate(table) if i == 0 or row[1] == elem] %>
                <% plotter.hash_vars[key] = subtable %>
                <% txt = [] %>
                <% txt.append(plotter.boxplot(id= key, header= True, group = "Embedding", row_names= False, default= False, fields= [5],  smp_attr= [0,1,2,3], 
                                x_label= "AUROC",
                                title="",
                                config= {
                                        "graphOrientation": "vertical",
                                        "colorBy" : "seed",
                                        "groupingFactors" :
                                         ["seed"],
                                        "jitter": True,
                                        "showBoxplotIfViolin": True,
                                        "showBoxplotOriginalData": True,
                                        "showLegend": False,
                                        "showViolinBoxplot": True,
                                        "smpLabelScaleFontFactor": 0.3,
                                        "smpTextRotate":45,
                                        "setMinX": 0})) %>
                <% txt.append(ph.make_title(plotter,"figure",f"figure_dragon_{elem}", f"""Distributioon of AUROC obtained on 10-fold-CV by
                 each seed and individual eGSM for {elem}")"""))%>
                <% macro_click_txt.append(ph.collapsable_data(plotter,f"{elem}: AUROC by seed", None, f"dragon_plot_{elem}", "\n".join(txt))) %>
        % endfor
        ${ph.collapsable_data(plotter,"Individual eGSM", 'clickme_id'+"general", 'container'+"general","\n".join(macro_click_txt), True, hlevel=3)}

% endif 

% if plotter.hash_vars.get('integrated_rank_size_auc_by_group') is not None: 

        <%
                table = plotter.hash_vars["integrated_rank_size_auc_by_group"]
                ids = list(set([ row[1] for i,row in enumerate(table) if i > 0]))
                ids.sort()
        %>
        <% macro_click_txt = [] %>
        % for elem in ids:
                <% key = "integrated_rank_size_auc_by_group" + elem %>
                <% subtable = [row for i, row in enumerate(table) if i == 0 or row[1] == elem] %>
                <% plotter.hash_vars[key] = subtable %>
                <% txt = [] %>
                <% txt.append(plotter.boxplot(id= key, header= True, group = "Embedding", row_names= False, default= False, fields= [5],  smp_attr= [0,1,2,3], 
                                x_label= "AUROC",
                                title="",
                                config= {
                                        "graphOrientation": "vertical",
                                        "colorBy" : "seed",
                                        "groupingFactors" :
                                         ["seed"],
                                        "jitter": True,
                                        "showBoxplotIfViolin": True,
                                        "showBoxplotOriginalData": True,
                                        "showLegend": False,
                                        "showViolinBoxplot": True,
                                        "smpLabelScaleFontFactor": 0.3,
                                        "smpTextRotate":45,
                                        "setMinX": 0})) %>
                <% txt.append(ph.make_title(plotter,"figure",f"figure_dragon_{elem}", f"""Distributioon of AUROC obtained on 10-fold-CV by
                 each seed and integrated eGSM for {elem}")"""))%>
                <% macro_click_txt.append(ph.collapsable_data(plotter,f"{elem}: AUROCs by seed", None, f"dragon_plot_{elem}", "\n".join(txt))) %>
        % endfor
        ${ph.collapsable_data(plotter,"Integrated eGSM", 'clickme_id'+"general2", 'container'+"general2","\n".join(macro_click_txt), True, hlevel=3)}
% endif 

<% txt="Performance by Seed Size" %>
${plotter.create_title(txt, id='perf_by_seed_size', hlevel=2, indexable=True, clickable=False)}


<%
txt=[]
if plotter.hash_vars.get('non_integrated_rank_group_vs_posrank') is not None: 
           txt.append(plotter.scatter2D(id= 'non_integrated_rank_group_vs_posrank', header= True, fields = [5,4], x_label = 'Real Group Size', y_label = 'median rank', 
                title= " (A) Individual eGSM", smp_attr= [0,1,2,3], add_densities = True, config= {
                        'showLegend' : True,
                        "colorBy":"Embedding",
                        'segregateVariablesBy' : 'annot',
                        "titleFontStyle": "italic",
                        "varLabelFontSize": 5
                        }))
if plotter.hash_vars.get('integrated_rank_group_vs_posrank') is not None: 
        txt.append(plotter.scatter2D(id= 'integrated_rank_group_vs_posrank', header= True, fields = [5,4], x_label = 'Real Group Size', y_label = 'median rank', 
                title= " (B) Integrated eGSM", smp_attr= [0,1,2,3], add_densities = True, config= {
                        'showLegend' : True,
                        "colorBy":"Embedding",
                        'segregateVariablesBy' : 'integration',
                        "titleFontStyle": "italic",
                        "titleScaleFontFactor": 0.7
                        }))
txt.append(ph.make_title(plotter,"figure", "rank_size", f"""Rank vs Size in each individual (A) or integrated (B) eGSM."""))
%>
% if bench_type == "menche":
        ${ph.collapsable_data(plotter,"Normalized Ranks vs Size", "norm_rank_vs_size_click", "norm_rank_vs_size_collaps","\n".join(txt))}
% else:
        ${"\n".join(txt)}
% endif


% if plotter.hash_vars.get("non_integrated_rank_medianauc") is not None or plotter.hash_vars.get("integrated_rank_medianauc") is not None:
<div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
        % if plotter.hash_vars.get('non_integrated_rank_medianauc') is not None: 
           ${plotter.scatter2D(id= 'non_integrated_rank_medianauc', header= True, 
                fields = [4,5], x_label = 'Real Group Size', y_label = 'median AUROC', 
                title= " (A) Individual eGSM.", 
                smp_attr= [0,1,2,3], add_densities = True, config= {
                        'showLegend' : True,
                        "colorBy":"Embedding",
                        'segregateVariablesBy' : 'annot',
                        "titleFontStyle": "italic",
                        "titleScaleFontFactor": 0.7
                        })}
        % endif 
        % if plotter.hash_vars.get('integrated_rank_medianauc') is not None: 
            ${plotter.scatter2D(id= 'integrated_rank_medianauc', header= True,
             fields = [4,5], x_label = 'Real Group Size', y_label = 'median AUROC',
              title= " (B) Integrated eGSM.", 
              smp_attr= [0,1,2,3], add_densities = True, config= {
                        'showLegend' : True,
                        "colorBy":"Embedding",
                        'segregateVariablesBy' : 'method',
                        "titleFontStyle": "italic",
                        "titleScaleFontFactor": 0.7
                        })}
        % endif 
</div>
${ph.make_title(plotter,"figure", "roc_size", f"""Median AUROC vs Size in each individual (A) or integrated (B) eGSM.""")}
% endif