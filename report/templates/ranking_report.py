<%
        import os.path
        def order_columns(name, column):
                tab_header = plotter.hash_vars[name].pop(0)
                plotter.hash_vars[name].sort(key=lambda x: x[column])
                plotter.hash_vars[name].insert(0, tab_header)

        if plotter.hash_vars.get('parsed_non_integrated_rank_summary') is not None:
                order_columns('parsed_non_integrated_rank_summary',0)

        if plotter.hash_vars.get('parsed_integrated_rank_summary') is not None:
                order_columns('parsed_integrated_rank_summary',0)

        if plotter.hash_vars.get('parsed_non_integrated_rank_pos_cov') is not None:
                order_columns('parsed_non_integrated_rank_pos_cov',0)

        if plotter.hash_vars.get('parsed_integrated_rank_pos_cov') is not None:
                order_columns('parsed_integrated_rank_pos_cov',0)

        if plotter.hash_vars.get('parsed_annotation_grade_metrics') is not None:
                order_columns('parsed_annotation_grade_metrics',0)

        img_path="/mnt/scratch/users/bio_267_uma/federogc/executions/GraphPrioritizer/report/img/"
        
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
                                        ${plotter.boxplot(id= 'integrated_rank_size_auc_by_group', header= True, row_names= False, default= False, group=["sample"], fields= [5],  var_attr= [0,1,2,3], 
                                           title= "Distribution of ROC-AUCs in Dataset by Embeddings and seeds after Integration",
                                                x_label= "ROC-AUCs",
                                                config= {
                                                        "graphOrientation": "vertical",
                                                        "colorBy" : "seed",
                                                        "groupingFactors" :
                                                        ["seed", "method"],
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
                <div style="margin-right: 10px;">
                                 % if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group') is not None: 
                                  ${ plotter.scatter2D(id= 'non_integrated_rank_size_auc_by_group', header= True, title= "ROC-AUCs vs Group Size for Non integrated embeddings", fields = [4,5], x_label = 'Real Group Size', y_label = 'ROC-AUC', var_attr= [0,1,2,3], add_densities = True)}
                                % endif
                </div>
                <div style="margin-left: 10px;">
                                 % if plotter.hash_vars.get('integrated_rank_size_auc_by_group') is not None: 
                                 ${plotter.scatter2D(id= 'integrated_rank_size_auc_by_group', header= True, fields = [4,5], x_label = 'Real Group Size', y_label = 'ROC-AUC', title= "ROC-AUCs vs Group Size for integrated embeddings", var_attr= [0,1,2,3], add_densities = True)}
                                % endif
                </div>
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
                                                'graphOrientation' : 'vertical',
                                                "ribbonBy":[
                                                        "auc_down_ci_0.95",
                                                        "auc_up_ci_0.95"
                                                        ],
                                                "yAxis": ["auc"]
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
                                                'graphOrientation' : 'vertical',
                                                })}
                        % endif
                </div>
        </div>
        
        <!--
        <div style="overflow: hidden; display: flex; flex-direction: column; align-items: center;">
                % if plotter.hash_vars.get("non_integrated_rank_cdf") is not None: 
                        ${plotter.scatter2D(id=  "non_integrated_rank_cdf", fields=  [5,6] , header=  True, row_names=  False, responsive=  False,
                                height=  '400px', width=  '400px', x_label=  'Percentile/100', var_attr=  [0,1,2], y_label= "Cumulative frequency",
                                title=  "CDF for Non-Zero Scores Generated by Embeddings before Integration",
                                config=  {
                                        'showLegend' : True,
                                        'lineBy' : 'kernel',
                                        'colorBy' : 'kernel',
                                        'segregateVariablesBy' : 'annot'
                                        })}
                % endif
        </div>
        -->

        <div style="overflow: hidden; text-align:center">
                <p style="text-align:center;"> ROC Curves for Embeddings before Integration </p> 
                ${ plotter.embed_img(img_path+"non_integrated_ROC.png","width='700' height='700'")}
        </div>

        <!--
        <div style="overflow: hidden; display: flex; flex-direction: column; align-items: center;">
                % if plotter.hash_vars.get("integrated_rank_cdf") is not None: 
                        ${plotter.scatter2D(id=  "integrated_rank_cdf", fields=  [5,6] , header=  True, row_names=  False, responsive=  False,
                                height=  '400px', width=  '400px', x_label=  'Percentile/100', var_attr=  [0,1,2], y_label= "Cumulative frequency",
                                title=  "CDF for Non-Zero Scores Generated by Embeddings after Integration",
                                config=  {
                                        'showLegend' : True,
                                        'lineBy' : 'kernel',
                                        'colorBy' : 'kernel',
                                        'segregateVariablesBy' : 'integration'
                                        })}
                % endif
        </div>
        -->


        <div style="overflow: hidden; text-align:center">
                <p style="text-align:center;"> ROC Curves for Embeddings after Integration </p> 
                 % if os.path.exists(img_path+"integrated_ROC.png"): 
                        ${ plotter.embed_img(img_path+"integrated_ROC.png","width='700' height='700'")}
                 % endif
        </div>

</div>
















