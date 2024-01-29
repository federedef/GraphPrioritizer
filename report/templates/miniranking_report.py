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
                print(df.dtypes)
                df[value] = pd.to_numeric(df[value])
                print(df.dtypes)
                median_by_attributes = df.groupby(groupby)[value].mean().reset_index()
                len_by_attributes = df.groupby(groupby)[value].size().reset_index()
                concatenated_df = pd.concat([median_by_attributes, len_by_attributes[[value]]], axis=1)
                col_names = plotter.hash_vars[var_name][0]
                col_names.append("size")
                print([col_names])
                return [col_names] + concatenated_df.values.tolist()

        def plot_with_facet(data, plotter_list, plot_type="", x='fpr', y='tpr', col=None, hue=None, col_wrap=4, suptitle=None, top=0.7, labels = None, x_label=None, y_label=None):
                if plot_type == "scatterplot":
                        g = plotter_list["sns"].FacetGrid(data, col_wrap=col_wrap, col=col, hue=hue, aspect=1).map(plotter_list["sns"].scatterplot, x, y, alpha=0.7)
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
        
        df = pd.DataFrame(plotter.hash_vars["non_integrated_rank_cdf"][1:], columns = plotter.hash_vars["non_integrated_rank_cdf"][0])
        wide_df = df.pivot_table(index=['group_seed','candidate'], columns='annot_kernel', values=['rank'])
        wide_df.fillna(1, inplace=True)
        wide_df = wide_df.reset_index()
        wide_df = wide_df.T.reset_index()
        wide_df = wide_df[wide_df['level_0'] == 'rank']
        rownames_df = wide_df.iloc[:, :2]
        wide_df = wide_df.iloc[:, 2:]
        print("Wide DataFrame:")
        print(wide_df)

        from sklearn.decomposition import PCA
        from sklearn.preprocessing import StandardScaler
        pca = PCA(n_components=2)
        pca.fit(wide_df)
        X_pca = pca.transform(wide_df)
        principal_components_df = pd.DataFrame(data=X_pca, columns=[f'PC{i+1}' for i in range(2)])
        result_df = pd.concat([rownames_df[['level_0', 'annot_kernel']], principal_components_df], axis=1)
        result_df = result_df.dropna()
        result_values = result_df.values.tolist()
        result_values.insert(0,["rank","annot_kernel","PCA1","PCA2"])
        plotter.hash_vars["pca"] = result_values
        print(pca.explained_variance_ratio_)

        # Print the result
        print("Resulting DataFrame with Principal Components:")
        print(result_values)

%>
<div style="width:90%; background-color:#FFFFFF; margin:50 auto; align-content: center;">

    <h1 style="text-align:center; background-color:#ecf0f1, color: powderblue; "> Analysis of the algorithm: From rankings to prioritized genes.</h1>

        <h2 style="text-align:center; background-color:#ecf0f1, color: powderblue;"> Ranking section </h2>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">

                % if plotter.hash_vars.get('non_integrated_rank_group_vs_posrank') is not None: 
                   ${ plotter.static_plot_main( id="non_integrated_rank_group_vs_posrank", header=True, row_names=False, var_attr=[0,1,2,3], 
                        plotting_function= lambda data, plotter_list: plot_with_facet(data=data, plotter_list=plotter_list, plot_type="scatterplot", x='size', y='rank', col="annot",
                         hue="kernel", col_wrap=4, suptitle="Rank CDF vs Real Group Size before Integration", top=0.9, labels = None, x_label="Real Group Size", y_label="median-rank"))}
                % endif 

                ${plotter.scatter2D(id= 'pca', header= True, fields = [2,3], x_label = 'Real Group Size',
y_label = 'median-rank', title= "ROC-AUCs vs Group Size for integrated embeddings", var_attr= [0,1], add_densities = True, config= {
                                'showLegend' : True,
                                "colorBy":"annot_kernel"
                                })}
                
                ${plotter.scatter2D(id= 'non_integrated_rank_group_vs_posrank', header= True, fields = [5,4], x_label = 'Real Group Size',
y_label = 'median-rank', title= "ROC-AUCs vs Group Size for integrated embeddings", var_attr= [0,1,2,3], add_densities = True, config= {
                                'showLegend' : True,
                                "colorBy":"kernel",
                                'segregateVariablesBy' : 'annot',
                                'sizeBy': "size"
                                })}

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                % if plotter.hash_vars.get('integrated_rank_group_vs_posrank') is not None: 
                   ${ plotter.static_plot_main( id="integrated_rank_group_vs_posrank", header=True, row_names=False, var_attr=[0,1,2,3], 
                        plotting_function= lambda data, plotter_list: plot_with_facet(data=data, plotter_list=plotter_list, plot_type="scatterplot", x='size', y='rank', col="integration",
                         hue="kernel", col_wrap=2, suptitle="Rank CDF vs Real Group Size after Integration", top=0.9, labels = None, x_label="Real Group Size", y_label="median-rank"))}
                % endif 
        </div>
</div>