<%
        import os.path
        import warnings
        import pandas as pd
        warnings.simplefilter(action='ignore', category=FutureWarning)

        def get_medianrank_size(var_name, groupby = ['annot_kernel','annot','kernel','group_seed'], value = 'rank'):
                df = pd.DataFrame(plotter.hash_vars[var_name][1:], columns = plotter.hash_vars[var_name][0])
                median_by_attributes = df.groupby(groupby)[value].median().reset_index()
                print("eyyyyyyyyyyyyyyyyyy-1")
                len_by_attributes = df.groupby(groupby)[value].size().reset_index()
                print("eyyyyyyyyyyyyyyyyyy-2")
                concatenated_df = pd.concat([median_by_attributes, len_by_attributes[[value]]], axis=1)
                concatenated_df = concatenated_df.dropna()
                print("eyyyyyyyyyyyyyyyyyy-3")
                col_names = plotter.hash_vars[var_name][0]
                print("eyyyyyyyyyyyyyyyyyy-4")
                print(concatenated_df)
                col_names.append("size")
                return [col_names] + concatenated_df.values.tolist()
        
        if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group'):
                print(plotter.hash_vars['non_integrated_rank_size_auc_by_group'][1])
                plotter.hash_vars['non_integrated_rank_size_auc_by_group'] = get_medianrank_size('non_integrated_rank_size_auc_by_group', groupby = ["sample","annot","kernel","seed","pos_cov"], value = 'auc')
        if plotter.hash_vars.get('integrated_rank_size_auc_by_group'):
                plotter.hash_vars["integrated_rank_size_auc_by_group"] = get_medianrank_size("integrated_rank_size_auc_by_group", groupby = ["sample","method","kernel","seed","pos_cov"], value = 'auc')

%>
<% 
        print(float(plotter.hash_vars['non_integrated_rank_size_auc_by_group'][1][4]))
        # for row in plotter.hash_vars['non_integrated_rank_size_auc_by_group'][1:]:
        #         print(row[4])
        #         print(float(row[4]))

        print([ float(row[4]) for row in plotter.hash_vars["integrated_rank_size_auc_by_group"][1:]])
        print("ajaaaaaaaaaa     aaaaa")
%>

<div style="margin-right: 10px;">
                 % if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group') is not None: 
                        ${plotter.boxplot(id= 'non_integrated_rank_size_auc_by_group', header= True, row_names= False, default= False, fields= [5],  var_attr= [0,1,2,3], group = ["kernel"],
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
                 % if plotter.hash_vars.get('integrated_rank_size_auc_by_group') is not None: 
                        ${plotter.boxplot(id= 'integrated_rank_size_auc_by_group', header= True, row_names= False, default= False, fields= [5],  var_attr= [0,1,2], group = ["kernel"],
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

<div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
        % if plotter.hash_vars.get('non_integrated_rank_size_auc_by_group') is not None: 
           ${plotter.scatter2D(id= 'non_integrated_rank_size_auc_by_group', header= True, 
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
        % if plotter.hash_vars.get('integrated_rank_size_auc_by_group') is not None: 
            ${plotter.scatter2D(id= 'integrated_rank_size_auc_by_group', header= True,
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
