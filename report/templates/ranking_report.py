<%
        import os.path
        import warnings
        import pandas as pd
        warnings.simplefilter(action='ignore', category=FutureWarning)
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

        img_path="/mnt/scratch/users/bio_267_uma/federogc/executions/GraphPrioritizer/report/img/"

        if plotter.hash_vars.get('non_integrated_rank_group_vs_posrank') is not None:
                plotter.hash_vars["non_integrated_rank_group_vs_posrank"] = get_medianrank_size('non_integrated_rank_group_vs_posrank', groupby = ['annot_kernel','annot','kernel','group_seed'], value = 'rank')
        if plotter.hash_vars.get('integrated_rank_group_vs_posrank') is not None:
                plotter.hash_vars["integrated_rank_group_vs_posrank"] = get_medianrank_size('integrated_rank_group_vs_posrank', groupby = ['integration_kernel','integration','kernel','group_seed'], value = 'rank')

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
<div style="width:90%; background-color:#FFFFFF; margin:50 auto; align-content: center;">

    <h1 style="text-align:center; background-color:#ecf0f1, color: powderblue; "> Analysis of the algorithm: From rankings to prioritized genes.</h1>

        <h2 style="text-align:center; background-color:#ecf0f1, color: powderblue;"> Ranking section </h2>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                <div style="margin-right: 10px;">
                        % if plotter.hash_vars.get('parsed_non_integrated_rank_pos_cov') is not None:
                                ${plotter.barplot(id='parsed_non_integrated_rank_pos_cov', responsive= False, header=True,
                                 fields = [1,3],
                                 x_label = 'Number of control candidate genes present',
                                 height = '400px', width= '400px',
                                 var_attr = [1,2],
                                 title = "Control Coverage by Layers before Integration",
                                 config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'horizontal',
                                        'colorBy' : 'Kernel',
                                        'setMinX': 0
                                        })}
                % endif
                </div>
                <div style="margin-left: 10px;"> 
                        % if plotter.hash_vars.get('parsed_integrated_rank_pos_cov') is not None: 
                                ${plotter.barplot(id= "parsed_integrated_rank_pos_cov", fields= [1,3] , header= True, responsive= False,
                                        height= '400px', width= '400px', x_label= 'Number of control candidate genes present' , var_attr= [1,2],
                                        title = "Control Coverage by Layers after Integration",
                                        config = {
                                                'showLegend' : True,
                                                'graphOrientation' : 'horizontal',
                                                'colorBy' : 'Kernel',
                                                'setMinX': 0
                                                })}
                        % endif
                </div>
        </div>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                <div style="margin-right: 10px;">
                                 % if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group') is not None: 
                                        ${plotter.boxplot(id= 'non_integrated_rank_size_auc_by_group', header= True, row_names= False, default= False, fields= [5],  var_attr= [0,1,2,3], group = ["kernel"],
                                           title= "Distribution of ROC-AUCs in Dataset by Embeddings and seeds before Integration",
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
                                                        "setMinX": 0})}
                                % endif
                </div>
                <div style="margin-left: 10px;">
                                 % if plotter.hash_vars.get('integrated_rank_size_auc_by_group') is not None: 
                                        ${plotter.boxplot(id= 'integrated_rank_size_auc_by_group', header= True, row_names= False, default= False, fields= [5],  var_attr= [0,1,2], group = ["kernel"],
                                           title= "Distribution of ROC-AUCs in Dataset by Embeddings and seeds after Integration",
                                                x_label= "ROC-AUCs",
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
                                                        "setMinX": 0})}
                                % endif
                </div>
        </div>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                <div style="margin-left: 10px;">
                                 % if plotter.hash_vars.get('non_integrated_rank_auc_by_groupIteration') is not None: 
                                        ${plotter.boxplot(id= 'non_integrated_rank_auc_by_groupIteration', header= True, group = "kernel",row_names= False, default= False, fields= [4],  var_attr= [0,1,2,3], 
                                           title= "Distribution of ROC-AUCs by iteration in dataset (before integration)",
                                                x_label= "ROC-AUCs",
                                                config= {
                                                        "graphOrientation": "vertical",
                                                        "colorBy" : "seed",
                                                        "groupingFactors" :
                                                        ["annot", "seed"],
                                                        "jitter": True,
                                                        "showBoxplotIfViolin": True,
                                                        "showBoxplotOriginalData": True,
                                                        "showLegend": False,
                                                        "showViolinBoxplot": True,
                                                        "setMinX": 0})}
                                % endif
                </div>
        </div>


        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                % if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group') is not None: 
                   ${ plotter.static_plot_main( id="non_integrated_rank_size_auc_by_group", header=True, row_names=False, var_attr=[0,1,2,3], 
                        plotting_function= lambda data, plotter_list: plot_with_facet(data=data, plotter_list=plotter_list, plot_type="lmplot", x='pos_cov', y='auc', col="annot",
                         hue="kernel", col_wrap=4, suptitle="Rank vs Real Group Size before Integration", top=0.9, labels = None, x_label="Real Group Size", y_label="AUC"))}
                % endif 
        </div>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                % if plotter.hash_vars.get('integrated_rank_size_auc_by_group') is not None: 
                   ${ plotter.static_plot_main( id="integrated_rank_size_auc_by_group", header=True, row_names=False, var_attr=[0,1,2,3], 
                        plotting_function= lambda data, plotter_list: plot_with_facet(data=data, plotter_list=plotter_list, plot_type="lmplot", x='pos_cov', y='auc', col="method",
                         hue="kernel", col_wrap=2, suptitle="Rank vs Real Group Size after Integration", top=0.8, labels = None, x_label="Real Group Size", y_label="AUC"))}
                % endif 
        </div>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                % if plotter.hash_vars.get('non_integrated_rank_group_vs_posrank') is not None: 
                   ${ plotter.static_plot_main( id="non_integrated_rank_group_vs_posrank", header=True, row_names=False, var_attr=[0,1,2,3], 
                        plotting_function= lambda data, plotter_list: plot_with_facet(data=data, plotter_list=plotter_list, plot_type="lmplot", x='size', y='rank', col="annot",
                         hue="kernel", col_wrap=4, suptitle="Rank CDF vs Real Group Size before Integration", top=0.9, labels = None, x_label="Real Group Size", y_label="median-rank"))}
                % endif 
        </div>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                % if plotter.hash_vars.get('integrated_rank_group_vs_posrank') is not None: 
                   ${ plotter.static_plot_main( id="integrated_rank_group_vs_posrank", header=True, row_names=False, var_attr=[0,1,2,3], 
                        plotting_function= lambda data, plotter_list: plot_with_facet(data=data, plotter_list=plotter_list, plot_type="lmplot", x='size', y='rank', col="method",
                         hue="kernel", col_wrap=2, suptitle="Rank CDF vs Real Group Size before Integration", top=0.9, labels = None, x_label="Real Group Size", y_label="median-rank"))}
                % endif 
        </div>


        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                <div style="margin-right: 10px;">
                                % if plotter.hash_vars.get('non_integrated_rank_cdf') is not None: 
                                        ${plotter.boxplot(id= 'non_integrated_rank_cdf', header= True, row_names= False, default= False, fields= [5],  var_attr= [0,1,2], group = "kernel",
                                           title= "Distribution of Non-Zero Ranks in Dataset by Embeddings before Integration",
                                                x_label= "Percentile/100",
                                                config= {
                                                        "graphOrientation": "vertical",
                                                        "colorBy" : "kernel",
                                                        "groupingFactors" :
                                                        ["kernel"],
                                                        "segregateSamplesBy": "annot"})}
                                % endif
                </div>
                <div style="margin-left: 10px;">
                                % if plotter.hash_vars.get('integrated_rank_cdf') is not None: 
                                        ${plotter.boxplot(id= 'integrated_rank_cdf', header= True, row_names= False, default= False, fields = [5], var_attr= [0,1,2], group= "kernel", 
                                                title= "Distribution of Non-Zero Ranks in Dataset by Embeddings after Integration",
                                                xlabel= "Percentile/100",
                                                config= {
                                                        "graphOrientation": "vertical",
                                                        "colorBy" : "kernel",
                                                        "xAxisTitle": "Percentile/100",
                                                        "groupingFactors" :
                                                        ["kernel"],
                                                        "segregateSamplesBy": "integration"})}
                                % endif
                </div>
        </div>


        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue;">  </h3>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                <div style="margin-right: 10px;">
                        % if plotter.hash_vars.get("parsed_non_integrated_rank_summary") is not None: 
                                ${plotter.line(id= "parsed_non_integrated_rank_summary", fields= [0, 7, 13, 8], header= True, row_names= True,
                                        responsive= False,
                                        height= '400px', width= '400px', x_label= 'AUC',
                                        title= "Bootstrap Distribution of ROC-AUC for Embeddings before Integration",
                                        config= {
                                                'showLegend' : True,
                                                'graphOrientation' : 'vertical'
                                                })}
                        % endif
                </div>
                <div style="margin-left: 10px;">
                        % if plotter.hash_vars.get('parsed_integrated_rank_summary') is not None: 
                                ${plotter.line(id= "parsed_integrated_rank_summary", fields=  [0, 7, 13, 8], header= True, row_names= True,
                                        responsive= False,
                                        height= '400px', width= '400px', x_label= 'AUC',
                                        title= "Bootstrap Distribution of ROC-AUC for Embeddings after Integration",
                                        config= {
                                                'showLegend' : True,
                                                'graphOrientation' : 'vertical'
                                                })}
                        % endif
                </div>
        </div>
        

        <div style="overflow: hidden; text-align:center">
                % if plotter.hash_vars.get("non_integrated_rank_cdf") is not None: 
                        ${ plotter.static_plot_main( id="non_integrated_rank_cdf", header=True, row_names=False, var_attr=[0,1,2,3], fields =[4,5,6],
                                        plotting_function= lambda data, plotter_list: plot_with_facet(plot_type="ecdf",data=data, 
                                                plotter_list=plotter_list, x="rank", col="annot", 
                                                hue="kernel", col_wrap=4, 
                                                suptitle="CDF for Non-Zero Scores Generated by Embeddings before Integration",x_label="Rank", top=0.9))}
                % endif
        </div>

        <div style="overflow: hidden; text-align:center">
                % if plotter.hash_vars.get("non_integrated_rank_measures") is not None: 
                         ${ plotter.static_plot_main( id="non_integrated_rank_measures", header=True, row_names=False, var_attr=[0,1,2,3], fields =[4,5,6],
                                        plotting_function= lambda data, plotter_list: plot_with_facet(plot_type="lineplot", data=data,
                                                plotter_list=plotter_list, x='fpr', y='tpr', col='annot', 
                                                hue='kernel', col_wrap=4, suptitle="ROC Curve Generated by Embeddings before Integration", 
                                                top=0.9, x_label="FPR", y_label="TPR"))}
                % endif
        </div>


        <div style="overflow: hidden; text-align:center">
                % if plotter.hash_vars.get("integrated_rank_cdf") is not None: 
                        ${ plotter.static_plot_main( id="integrated_rank_cdf", header=True, row_names=False, var_attr=[0,1,2,3], fields =[4,5,6],
                                        plotting_function= lambda data, plotter_list: plot_with_facet(plot_type="ecdf",data=data, plotter_list=plotter_list, x="rank", 
                                                col="integration", hue="kernel", col_wrap=2, suptitle="CDF for Non-Zero Scores Generated by Embeddings after Integration", top=0.8))}
                % endif
        </div>

        <div style="overflow: hidden; text-align:center">
                % if plotter.hash_vars.get("integrated_rank_measures") is not None: 
                         ${ plotter.static_plot_main( id="integrated_rank_measures", header=True, row_names=False, var_attr=[0,1,2,3], fields =[4,5,6], 
                                        plotting_function= lambda data, plotter_list: plot_with_facet(plot_type="lineplot",data=data, 
                                                plotter_list=plotter_list, x='fpr', y='tpr', col='integration', 
                                                hue='kernel', col_wrap=2, suptitle="ROC Curve Generated by Embeddings after Integration", 
                                                top=0.8, labels = 'kernel', x_label="FPR", y_label="TPR"))}
                % endif
        </div>
</div>
















