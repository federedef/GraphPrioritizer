<%
        import os.path
        import warnings
        import pandas as pd
        import re
        warnings.simplefilter(action='ignore', category=FutureWarning)

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
                return collapsable_txt

        def make_title(type, id, sentence):
                if type == "table":
                        key = f"tab:{id}"
                        html_title = f"<p style='text-align:center;'> <b> {type.capitalize()} {plotter.add_table(key)} </b> {sentence} </p>"
                elif type == "figure":
                        key = id
                        html_title = f"<p style='text-align:center;'> <b> {type.capitalize()} {plotter.add_figure(key)} </b> {sentence} </p>"
                return html_title

        # Parse tables
        ##############


        def order_columns(name, column):
                tab_header = plotter.hash_vars[name].pop(0)
                plotter.hash_vars[name].sort(key=lambda x: x[column])
                plotter.hash_vars[name].insert(0, tab_header)

        def get_medianrank_size(var_name, groupby = ['annot_kernel','annot','kernel','group_seed'], value = 'rank'):
                df = pd.DataFrame(plotter.hash_vars[var_name][1:], columns = plotter.hash_vars[var_name][0])
                median_by_attributes = df.groupby(groupby)[value].median().reset_index()
                len_by_attributes = df.groupby(groupby)[value].size().reset_index()
                concatenated_df = pd.concat([median_by_attributes, len_by_attributes[[value]]], axis=1)
                col_names = plotter.hash_vars[var_name][0]
                col_names.append("size")
                return [col_names] + concatenated_df.values.tolist()

        def parsed_string(data, blacklist = ["sim"]):
                words = []
                for word in data.split("_"):
                        for blackword in blacklist:
                                word = re.sub(blackword,"",word)
                        word = word.capitalize()
                        words.append(word)
                parsed_data = " ".join(words)
                return parsed_data

        def parse_data(table, blacklist = ["sim"], column = "all"):
                parsed_table = []
                for i,row in enumerate(table):
                        parsed_table.append(row)
                        for j,data in enumerate(row):
                                if type(data) == str and not data.startswith("HGNC:"):
                                        parsed_table[i][j] = parsed_string(data, blacklist)
                                else:
                                        continue
                return parsed_table
                
        def parse_table(name, blacklist=["sim"], include_header = False):
                if not include_header:
                        tab_header = plotter.hash_vars[name].pop(0)
                        plotter.hash_vars[name] = parse_data(plotter.hash_vars[name])
                        plotter.hash_vars[name].insert(0, tab_header)
                else:
                        plotter.hash_vars[name] = parse_data(plotter.hash_vars[name])

        # Parse plot
        ############

        def plot_with_facet(data, plotter_list, plot_type="", x='fpr', y='tpr', col=None, hue=None, col_wrap=4, suptitle=None, top=0.7, labels = None, x_label=None, y_label=None):
                if plot_type == "scatterplot":
                        g = plotter_list["sns"].FacetGrid(data, col_wrap=col_wrap, col=col, hue=hue, aspect=1).map(plotter_list["sns"].scatterplot, x, y)
                elif plot_type == "lineplot":
                        g = plotter_list["sns"].FacetGrid(data, col_wrap=col_wrap, col=col, hue=hue, aspect=1).map(plotter_list["sns"].lineplot, x, y)
                elif plot_type == "ecdf":   
                        g = plotter_list["sns"].FacetGrid(data, col_wrap=col_wrap, col=col, hue=hue, aspect=1).map(plotter_list["sns"].ecdfplot, x)
                elif plot_type == "lmplot":
                        g = plotter_list["sns"].lmplot(data=data, x=x, y=y, hue=hue, col=col, col_wrap=col_wrap)

                if x_label: g.set_xlabels(x_label)
                if y_label: g.set_ylabels(y_label)
                g.add_legend()
                g.set_titles(col_template="{col_name}")
                if suptitle is not None:
                        g.fig.subplots_adjust(top=top)
                        g.fig.suptitle(suptitle,fontsize=20)     
%>
<%
        # Parsing tables
        ################

        for table in plotter.hash_vars.keys():
                parse_table(table)

        if plotter.hash_vars.get('parsed_non_integrated_rank_summary') is not None:
                order_columns('parsed_non_integrated_rank_summary',0)

        if plotter.hash_vars.get('parsed_integrated_rank_summary') is not None:
                order_columns('parsed_integrated_rank_summary',0)

        if plotter.hash_vars.get('parsed_non_integrated_rank_pos_cov') is not None:
                order_columns('parsed_non_integrated_rank_pos_cov',2)
                order_columns('parsed_non_integrated_rank_pos_cov',1)
   
        if plotter.hash_vars.get('parsed_integrated_rank_pos_cov') is not None:
                order_columns('parsed_integrated_rank_pos_cov',2)
                order_columns('parsed_integrated_rank_pos_cov',1)
           
        if plotter.hash_vars.get('parsed_annotation_grade_metrics') is not None:
                order_columns('parsed_annotation_grade_metrics',0)

        if plotter.hash_vars.get('non_integrated_rank_group_vs_posrank') is not None:
                plotter.hash_vars["non_integrated_rank_group_vs_posrank"] = get_medianrank_size('non_integrated_rank_group_vs_posrank', groupby = ['annot_kernel','annot','kernel','group_seed'], value = 'rank')
        if plotter.hash_vars.get('integrated_rank_group_vs_posrank') is not None:
                plotter.hash_vars["integrated_rank_group_vs_posrank"] = get_medianrank_size('integrated_rank_group_vs_posrank', groupby = ['integration_kernel','integration','kernel','group_seed'], value = 'rank')
        if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group'):
                plotter.hash_vars['non_integrated_rank_medianauc'] = get_medianrank_size('non_integrated_rank_size_auc_by_group', groupby = ["sample","annot","kernel","seed","pos_cov"], value = 'auc')
        if plotter.hash_vars.get('integrated_rank_size_auc_by_group'):
                plotter.hash_vars["integrated_rank_medianauc"] = get_medianrank_size("integrated_rank_size_auc_by_group", groupby = ["sample","method","kernel","seed","pos_cov"], value = 'auc')

%>
<div style="width:90%; background-color:#FFFFFF; margin:50 auto; align-content: center;">

    <h1 style="text-align:center; background-color:#ecf0f1, color: powderblue; "> Analysis of the algorithm: From rankings to prioritized genes.</h1>
        % if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group') is not None: 
                <div>
                        <%
                                graph=f"""
                                ---
                                title: Menche Benchmarking Flux
                                config:
                                 theme: dark
                                 themeVariables:
                                  lineColor: "#717171"
                                ---
                                graph LR;
                                 ORPHA[(OrphaNet)]
                                 A[Seeds]
                                 S((<span style="color:#000000">seed</span>))
                                 B[10-fold CV]
                                 C[Iteration 1]
                                 D[Iteraction 2]
                                 E[...]
                                 F[Iteration 10]
                                 I[<span style="color:#8B0000">Negative</span>]
                                 J[<span style="color:#023020">Positive</span>]
                                 G[<span style="color:#000000">ROC</span>]
                                 cdf[<span style="color:#000000">CDF</span>]
                                 Coverage[<span style="color:#000000">Coverage</span>]
                                 ORPHA --Aggregated groups <br> n&ge;20--> A
                                 S --> B 
                                 A --> A
                                 A --> S
                                 subgraph Iterations
                                 C
                                 D 
                                 E 
                                 F    
                                 end
                                 B --> C
                                 B --> D
                                 B --> E
                                 B --> F
                                 Iterations --> J
                                 Iterations --> I
                                 I --> G
                                 J --> G
                                 J --> cdf
                                 J --> Coverage
                                 style I fill:#FF503E
                                 style J fill:#84D677
                                 style cdf fill:#A0A0A0
                                 style G fill:#A0A0A0
                                 style S fill:#A0A0A0
                                 style Coverage fill:#A0A0A0
                                """
                        %>
                        ${plotter.mermaid_chart(graph)}
                </div>
                ${make_title("figure", "seed_wflow", """Workflow of the benchmarking process. Seeds are obtained from Orphanet disease genes agglomeration with n &ge; 20.
                 Then, a 10-fold CV is performed for each seed, obtaining positives and using genome background as negatives.""")}    
        % else:
                <div>
                        <%
                                graph=f"""
                                ---
                                title: Zampieri Benchmarking Flux
                                config:
                                 theme: dark
                                 themeVariables:
                                  lineColor: "#717171"
                                ---
                                graph LR;
                                 ORPHA[(OMIM)]
                                 A[Seeds]
                                 S((<span style="color:#000000">seed</span>))
                                 B[Leave One Out]
                                 C[Iteration 1]
                                 D[Iteraction 2]
                                 E[...]
                                 F[Iteration n]
                                 I[<span style="color:#8B0000">Negative</span>]
                                 J[<span style="color:#023020">Positive</span>]
                                 G[<span style="color:#000000">ROC</span>]
                                 cdf[<span style="color:#000000">CDF</span>]
                                 Coverage[<span style="color:#000000">Coverage</span>]
                                 ORPHA --Aggregated groups <br> n&ge;30--> A
                                 S --> B 
                                 A --> A
                                 A --> S
                                 subgraph Iterations
                                 C
                                 D 
                                 E 
                                 F    
                                 end
                                 B --> C
                                 B --> D
                                 B --> E
                                 B --> F
                                 Iterations --> J
                                 Iterations --> I
                                 I --> G
                                 J --> G
                                 J --> cdf
                                 J --> Coverage
                                 style I fill:#FF503E
                                 style J fill:#84D677
                                 style cdf fill:#A0A0A0
                                 style G fill:#A0A0A0
                                 style S fill:#A0A0A0
                                 style Coverage fill:#A0A0A0
                                """
                        %>
                        ${ plotter.mermaid_chart(graph)}
                </div>
                ${make_title("figure", "seed_wflow", """Workflow of the benchmarking process. Seeds are obatined from OMIM disease genes agglomeration with n &ge; 30.
                 Then, leave one out is performed for each seed, obtaining positives and using genes in others seeds as negatives.""")}    
        % endif

        <div style="overflow: hidden";>
                <div style="overflow: hidden";>
                        % if plotter.hash_vars.get('control_pos') is not None:
                                <% txt = [make_title("table","table_seedgroups", "Seed groups.")] %>
                                <% txt.append(plotter.table(id='control_pos', header=True,  text= True, row_names = True, fields= [0,1], styled='dt', border= 2, attrib = {
                                        'class' : "table table-striped table-dark"}))%>
                                ${collapsable_data("Positive control (click me)", "positive_control_table", "\n".join(txt))}
                        % endif

                </div>
        </div>

        <h2 style="text-align:center; background-color:#ecf0f1, color: powderblue;"> Ranking section </h2>


        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                <div style="margin-right: 10px;">
                        % if plotter.hash_vars.get('parsed_non_integrated_rank_pos_cov') is not None:
                                ${plotter.barplot(id='parsed_non_integrated_rank_pos_cov', responsive= False, header=True,
                                 fields = [1,3],
                                 x_label = 'Number of control candidate \n genes present',
                                 height = '400px', width= '400px',
                                 var_attr = [1,2],
                                 title = "Coverage by individual layers",
                                 config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'horizontal',
                                        'colorBy' : 'Kernel',
                                        'setMinX': 0,
                                        "titleFontStyle": "italic",
                                        "titleScaleFontFactor": 0.3
                                        })}
                % endif
                </div>
                <div style="margin-left: 10px;"> 
                        % if plotter.hash_vars.get('parsed_integrated_rank_pos_cov') is not None: 
                                ${plotter.barplot(id= "parsed_integrated_rank_pos_cov", fields= [1,3] , header= True, responsive= False,
                                        height= '400px', width= '400px', x_label= 'Number of control candidate \n genes present' , var_attr= [1,2],
                                        title = "Coverage by integrated layers",
                                        config = {
                                                'showLegend' : True,
                                                'graphOrientation' : 'horizontal',
                                                'colorBy' : 'Kernel',
                                                'setMinX': 0,
                                                "titleFontStyle": "italic",
                                                "titleScaleFontFactor": 0.3
                                                })}
                        % endif
                </div>
        </div>
        ${make_title("figure", "coverage_bars", """Coverage obtained in each individual (A)
         or integrated (B) layers. In both plots, x axis reflects the number of positive control genes with information on the adjacency matrix, 
         with zero or minimum value on edges for the corresponding seed.""")}

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                <div style="margin-right: 10px;">
                                % if plotter.hash_vars.get('non_integrated_rank_cdf') is not None: 
                                        ${plotter.boxplot(id= 'non_integrated_rank_cdf', header= True, row_names= False, default= False, fields= [5],  var_attr= [0,1,2], group = "kernel",
                                           title= "(A) Rank distributions by \n individual layers embeddings",
                                                x_label= "Normalized rank",
                                                config= {
                                                        "graphOrientation": "vertical",
                                                        "colorBy" : "kernel",
                                                        "groupingFactors" :
                                                        ["kernel"],
                                                        "titleFontStyle": "italic",
                                                        "titleScaleFontFactor": 0.3,
                                                        "segregateSamplesBy": "annot"})}
                                % endif
                </div>
                <div style="margin-left: 10px;">
                                % if plotter.hash_vars.get('integrated_rank_cdf') is not None: 
                                        ${plotter.boxplot(id= 'integrated_rank_cdf', header= True, row_names= False, default= False, fields = [5], var_attr= [0,1,2], group= "kernel", 
                                                title= "(B) Rank distributions integrated layers",
                                                xlabel= "Normalized rank",
                                                config= {
                                                        "graphOrientation": "vertical",
                                                        "colorBy" : "kernel",
                                                        "xAxisTitle": "Normalized rank",
                                                        "groupingFactors" :
                                                        ["kernel"],
                                                        "titleFontStyle": "italic",
                                                        "titleScaleFontFactor": 0.3,
                                                        "segregateSamplesBy": "integration"})}
                                % endif
                </div>
        </div>
        ${make_title("figure", "rank_boxplot", f"""Rank distributions in each individual (A)
         or integrated (B) layers. In both plots, y axis ({italic("Normalized ranks")}) represent the rank normalized on 0-1 range.""")}

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                <div style="margin-right: 10px;">
                                 % if plotter.hash_vars.get('non_integrated_rank_medianauc') is not None: 
                                        ${plotter.boxplot(id= 'non_integrated_rank_medianauc', header= True, row_names= False, default= False, fields= [5],  var_attr= [0,1,2,3], group = ["kernel"],
                                           title= "(A) Median ROC-AUCs 10-fold-CV \n before Integration",
                                                x_label= "ROC-AUCs",
                                                config= {
                                                        "graphOrientation": "vertical",
                                                        "colorBy" : "kernel",
                                                        "groupingFactors" :
                                                        ["kernel"],
                                                        "segregateSamplesBy": "annot",
                                                        "jitter": True,
                                                        "showBoxplotIfViolin": True,
                                                        "showBoxplotOriginalData": True,
                                                        "showLegend":False,
                                                        "showViolinBoxplot":True,
                                                        "titleFontStyle": "italic",
                                                        "titleScaleFontFactor": 0.3,
                                                        "setMinX": 0})}
                                % endif
                </div>
                <div style="margin-left: 10px;">
                                 % if plotter.hash_vars.get('integrated_rank_medianauc') is not None: 
                                        ${plotter.boxplot(id= 'integrated_rank_medianauc', header= True, row_names= False, default= False, fields= [5],  var_attr= [0,1,2], group = ["kernel"],
                                           title= "(B) Median ROC-AUCs 10-fold-CV \n after Integration",
                                                x_label= "median ROC-AUCs",
                                                config= {
                                                        "graphOrientation": "vertical",
                                                        "colorBy" : "kernel",
                                                        "groupingFactors" :
                                                        ["kernel"],
                                                        "segregateSamplesBy": "method",
                                                        "jitter": True,
                                                        "showBoxplotIfViolin": True,
                                                        "showBoxplotOriginalData": True,
                                                        "showLegend": False,
                                                        "showViolinBoxplot": True,
                                                        "titleFontStyle": "italic",
                                                        "titleScaleFontFactor": 0.3,
                                                        "smpLabelRotate": 45,
                                                        "setMinX": 0})}
                                % endif
                </div>
        </div>
        ${make_title("figure", "roc_boxplot", f"""ROC-AUCs distributions in each individual (A)
         or integrated (B) layers. In both plots, y axis ({italic("median ROC-AUCs")}) represent the median of the 10-fold-CV ROC-AUCs for each seed.""")}

        <div style="overflow: hidden; text-align:center">
                % if plotter.hash_vars.get("non_integrated_rank_cdf") is not None: 
                        ${ plotter.static_plot_main( id="non_integrated_rank_cdf", header=True, row_names=False, var_attr=[0,1,2,3], fields =[4,5,6],
                                        plotting_function= lambda data, plotter_list: plot_with_facet(plot_type="ecdf",data=data, 
                                                plotter_list=plotter_list, x="rank", col="annot", 
                                                hue="kernel", col_wrap=4, 
                                                suptitle="A", x_label="Normalized Rank", y_label="Percent", top=0.9))}
                % endif
                % if plotter.hash_vars.get("integrated_rank_cdf") is not None: 
                        ${ plotter.static_plot_main( id="integrated_rank_cdf", header=True, row_names=False, var_attr=[0,1,2,3], fields =[4,5,6],
                                        plotting_function= lambda data, plotter_list: plot_with_facet(plot_type="ecdf",data=data, plotter_list=plotter_list, x="rank", 
                                                col="integration", hue="kernel", col_wrap=2, suptitle="B", x_label="Rank", y_label="Percent", top=0.8))}
                % endif
        </div>
        ${make_title("figure", "cdf_curve", f"""CDF curves by each individual (A)
         or integrated (B) layers. In both plots, y axis ({italic("Percent (%)")}) represent 
         the true positive rate and x axis ({italic("Normalized Rank")}) the rank normalized from 0 to 1.""")}

        <div style="overflow: hidden; text-align:center">
                % if plotter.hash_vars.get("non_integrated_rank_measures") is not None: 
                         ${ plotter.static_plot_main( id="non_integrated_rank_measures", header=True, row_names=False, var_attr=[0,1,2,3], fields =[4,5,6],
                                        plotting_function= lambda data, plotter_list: plot_with_facet(plot_type="lineplot", data=data,
                                                plotter_list=plotter_list, x='fpr', y='tpr', col='annot', 
                                                hue='kernel', col_wrap=4, suptitle="A", 
                                                top=0.9, x_label="FPR", y_label="TPR"))}
                % endif
                % if plotter.hash_vars.get("integrated_rank_measures") is not None: 
                         ${ plotter.static_plot_main( id="integrated_rank_measures", header=True, row_names=False, var_attr=[0,1,2,3], fields =[4,5,6], 
                                        plotting_function= lambda data, plotter_list: plot_with_facet(plot_type="lineplot",data=data, 
                                                plotter_list=plotter_list, x='fpr', y='tpr', col='integration', 
                                                hue='kernel', col_wrap=2, suptitle="B", 
                                                top=0.8, labels = 'kernel', x_label="FPR", y_label="TPR"))}
                % endif
        </div>
        ${make_title("figure", "roc_curve", f"""ROC in each individual (A) or integrated (B) layers.""")}

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue;">  </h3>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                <div style="margin-right: 10px;">
                        % if plotter.hash_vars.get("parsed_non_integrated_rank_summary") is not None: 
                                ${plotter.line(id= "parsed_non_integrated_rank_summary", fields= [0, 7, 13, 8], header= True, row_names= True,
                                        responsive= False,
                                        height= '400px', width= '400px', x_label= 'AUC',
                                        title= "(A) ROC-AUC ICs by each individual layer",
                                        config= {
                                                'showLegend' : True,
                                                'graphOrientation' : 'vertical',
                                                "titleFontStyle": "italic",
                                                "titleScaleFontFactor": 0.3
                                                })}
                        % endif
                </div>
                <div style="margin-left: 10px;">
                        % if plotter.hash_vars.get('parsed_integrated_rank_summary') is not None: 
                                ${plotter.line(id= "parsed_integrated_rank_summary", fields=  [0, 7, 13, 8], header= True, row_names= True,
                                        responsive= False,
                                        height= '400px', width= '400px', x_label= 'AUC',
                                        title= "(B) ROC-AUC ICs by integrated layer",
                                        config= {
                                                'showLegend' : True,
                                                'graphOrientation' : 'vertical',
                                                "titleFontStyle": "italic",
                                                "titleScaleFontFactor": 0.3,
                                                })}
                        % endif
                </div>
        </div>
        ${make_title("figure", "roc_ic", f"""ROC-AUC ICs in each individual (A) or integrated (B) layers. IC was obtained by a 1000 iteration bootstrap.""")}


        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                % if plotter.hash_vars.get('non_integrated_rank_group_vs_posrank') is not None: 
                   ${plotter.scatter2D(id= 'non_integrated_rank_group_vs_posrank', header= True, fields = [5,4], x_label = 'Real Group Size', y_label = 'median rank', 
                        title= " (A) Rank vs Group Size \n Individual layers", var_attr= [0,1,2,3], add_densities = True, config= {
                                'showLegend' : True,
                                "colorBy":"kernel",
                                'segregateVariablesBy' : 'annot',
                                "titleFontStyle": "italic",
                                "titleScaleFontFactor": 0.3
                                })}
                % endif 
                % if plotter.hash_vars.get('integrated_rank_group_vs_posrank') is not None: 
                   ${plotter.scatter2D(id= 'integrated_rank_group_vs_posrank', header= True, fields = [5,4], x_label = 'Real Group Size', y_label = 'median rank', 
                        title= " (B) Rank vs Group Size \n Integrated layers", var_attr= [0,1,2,3], add_densities = True, config= {
                                'showLegend' : True,
                                "colorBy":"kernel",
                                'segregateVariablesBy' : 'integration',
                                "titleFontStyle": "italic",
                                "titleScaleFontFactor": 0.3
                                })} 
                % endif 
        </div>
        ${make_title("figure", "rank_size", f"""Rank vs Size in each individual (A) or integrated (B) layers.""")}

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                % if plotter.hash_vars.get('non_integrated_rank_medianauc') is not None: 
                   ${plotter.scatter2D(id= 'non_integrated_rank_medianauc', header= True, 
                        fields = [4,5], x_label = 'Real Group Size', y_label = 'median AUROC', 
                        title= " (A) Median-AUROC vs Real Group Size before Integration", 
                        var_attr= [0,1,2,3], add_densities = True, config= {
                                'showLegend' : True,
                                "colorBy":"kernel",
                                'segregateVariablesBy' : 'annot',
                                "titleFontStyle": "italic",
                                "titleScaleFontFactor": 0.3
                                })}
                % endif 
                % if plotter.hash_vars.get('integrated_rank_medianauc') is not None: 
                    ${plotter.scatter2D(id= 'integrated_rank_medianauc', header= True,
                     fields = [4,5], x_label = 'Real Group Size', y_label = 'median AUROC',
                      title= " (B) Median-AUROC vs Real Group Size after Integration", 
                      var_attr= [0,1,2,3], add_densities = True, config= {
                                'showLegend' : True,
                                "colorBy":"kernel",
                                'segregateVariablesBy' : 'method',
                                "titleFontStyle": "italic",
                                "titleScaleFontFactor": 0.3
                                })}
                % endif 
        </div>
        ${make_title("figure", "roc_size", f"""Median-AUROC vs Size in each individual (A) or integrated (B) layers.""")}

        % if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group') is not None: 

                <%
                        table = plotter.hash_vars["non_integrated_rank_size_auc_by_group"]
                        ids = list(set([ row[1] for i,row in enumerate(table) if i > 0]))
                        ids.sort()
                %>

                % for elem in ids:
                        <% key = "non_integrated_rank_size_auc_by_group" + elem %>
                        <% subtable = [row for i, row in enumerate(table) if i == 0 or row[1] == elem] %>
                        <% plotter.hash_vars[key] = subtable %>
                        <% txt = [] %>
                        <% txt.append(plotter.boxplot(id= key, header= True, group = "kernel", row_names= False, default= False, fields= [5],  var_attr= [0,1,2,3], 
                                        x_label= "ROC-AUCs",
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
                                                "smpLabelRotate":45,
                                                "setMinX": 0})) %>
                        <% txt.append(make_title("figure",f"figure_dragon_{elem}", f"""Distributioon of ROC AUCs obtained on 10-fold-CV by
                         each seed and embedding for {elem} individual layer.")"""))%>
                        ${collapsable_data(f"{elem}: ROC-AUCs by seed (click me)", f"dragon_plot_{elem}", "\n".join(txt))}
                % endfor

        % endif 

        % if plotter.hash_vars.get('integrated_rank_size_auc_by_group') is not None: 

                <%
                        table = plotter.hash_vars["integrated_rank_size_auc_by_group"]
                        ids = list(set([ row[1] for i,row in enumerate(table) if i > 0]))
                        ids.sort()
                %>

                % for elem in ids:
                        <% key = "integrated_rank_size_auc_by_group" + elem %>
                        <% subtable = [row for i, row in enumerate(table) if i == 0 or row[1] == elem] %>
                        <% plotter.hash_vars[key] = subtable %>
                        <% txt = [] %>
                        <% txt.append(plotter.boxplot(id= key, header= True, group = "kernel", row_names= False, default= False, fields= [5],  var_attr= [0,1,2,3], 
                                        x_label= "ROC-AUCs",
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
                                                "smpLabelRotate":45,
                                                "setMinX": 0})) %>
                        <% txt.append(make_title("figure",f"figure_dragon_{elem}", f"""Distributioon of ROC AUCs obtained on 10-fold-CV by
                         each seed and embedding for {elem} individual layer.")"""))%>
                        ${collapsable_data(f"{elem}: ROC-AUCs by seed (click me)", f"dragon_plot_{elem}", "\n".join(txt))}
                % endfor

        % endif 

</div>
















