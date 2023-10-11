<%
        def order_columns(name, column):
                tab_header = plotter.hash_vars[name].pop(0)
                plotter.hash_vars[name].sort(key=lambda x: x[column])
                plotter.hash_vars[name].insert(0, tab_header)
        end
 
        if plotter.hash_vars.get('parsed_annotations_metrics') is not None:
                order_columns('parsed_annotations_metrics',0)

        if plotter.hash_vars.get('parsed_similarity_metrics') is not None:
                order_columns('parsed_similarity_metrics',0)

        if plotter.hash_vars.get('parsed_filtered_similarity_metrics') is not None:
                order_columns('parsed_filtered_similarity_metrics',0)

        if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                order_columns('parsed_uncomb_kernel_metrics',0)

        if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                order_columns('parsed_comb_kernel_metrics',0)
%>


<div style="width:90%; background-color:#FFFFFF; margin:50 auto; align-content: center;">
        <h1 style="text-align:center; background-color:#ecf0f1, color: powderblue; ">Analysis of the algorithm: From embeddings to prioritized genes.</h1>

        <p> The algorithm transformed the similarity matrix to make it compatible with the embedding process. Once this was done for each network and embedding type, it was integrated by embedding type. Below there is a general analysis of the properties of each matrix in the different phases of the process, including the graph building process for each layer. </p>

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue;"> Annotations Properties </h3>

        <div style="overflow: hidden";>
                <p style="text-align:center;"><b>Table 1.</b> Annotation descriptors. </p> 
                <div style="overflow: hidden";>
                        % if plotter.hash_vars.get('parsed_annotations_metrics') is not None:
                                ${plotter.table(id='parsed_annotations_metrics', header=True,  text= True, row_names = True, fields= [0,5,4,6,8], styled='bs', cell_align= ['left', 'center', 'center', 'center','center'], border= 2, attrib = {
                                        'style' : 'margin-left: auto; margin-right:auto;',
                                        'cellspacing' : 5,
                                        'cellpadding' : 2})}
                        % endif
                </div>
        </div>

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue;"> Individual Processing Graph steps </h3>
            <%
                table = plotter.hash_vars["parsed_final_stats_by_steps"]
                ids = list(set([ row[1] for i,row in enumerate(table) if i > 0]))
            %>

            % for elem in ids:
                <% key = "parsed_final_stats_by_steps_" + elem %>
                <% subtable = [row for i, row in enumerate(table) if i == 0 or row[1] == elem] %>
                <% plotter.hash_vars[key] = subtable %>
                <<div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
                ${plotter.barplot(id=key, fields= [2,6] , header= True, height= '400px', width= '400px', x_label= 'Density Element Not None', var_attr= [2],
                                        title = "Density matrix from " + elem,
                                        config = {
                                                'showLegend' : True,
                                                'graphOrientation' : 'vertical',
                                                'colorBy' : 'Step',
                                                'setMinX': 0,
                                                'setMaxX': 1
                                                })}
                ${plotter.barplot(id=key, fields= [2,22] , header= True, height= '400px', width= '400px', x_label= 'Number of nodes', var_attr= [2],
                                        title = "Number of nodes from " + elem,
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

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue;"> Embedding Process </h3>

        <div style="overflow: hidden;">
                <p style="text-align:center;"><b>Table 2.</b> Uncombined Embedding Matrixes </p> 
                % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                                ${plotter.table(id='parsed_uncomb_kernel_metrics', text= True, header=True, row_names = True, fields= [1,2,3,4,5,6], styled='bs', cell_align= ['left', 'left', 'center', 'center', 'center', 'center'], border= 2,attrib= {
                                        'style' : 'margin-left: auto; margin-right:auto;',
                                        'cellspacing' : 0,
                                        'cellpadding' : 2})}
                % endif
                <p style="text-align:center;"><b>Table 3.</b> Integrated Embedding Matrixes </p>
                % if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                                ${plotter.table(id='parsed_comb_kernel_metrics', text= True, header=True, row_names = True, fields= [1,2,3,4,5,6], styled='bs', cell_align= ['left', 'left', 'center', 'center', 'center', 'center'], border= 2,attrib= {
                                        'style' : 'margin-left: auto; margin-right:auto;',
                                        'cellspacing' : 0,
                                        'cellpadding' : 2})}
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

        <h3 style="text-align:center; background-color:#ecf0f1, color: powderblue;"> Weight values </h3>

        <div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">

                % if plotter.hash_vars.get('parsed_similarity_metrics') is not None:
                                ${plotter.line(id= "parsed_similarity_metrics", fields= [0, 17, 18, 19], header= True, row_names= True,
                                responsive= False,
                                height= '400px', width= '400px', x_label= 'Weight',
                                title= "Weight's similarity values",
                                config= {
                                        'showLegend' : True,
                                        'graphOrientation' : 'vertical',
                                        })}
                % endif

                % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                                ${plotter.line(id= "parsed_uncomb_kernel_metrics", fields= [0, 19, 20, 21], var_attr=[2], header= True, row_names= True,
                                responsive= False,
                                height= '400px', width= '400px', x_label= 'Weight',
                                title= "Weight's kernelized values before integration",
                                config= {
                                        'showLegend' : True,
                                        'graphOrientation' : 'vertical',
                                        'segregateSamplesBy' : 'Kernel'
                                        })}
                % endif

                % if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                                ${plotter.line(id= "parsed_comb_kernel_metrics", fields= [2, 19, 20, 21], var_attr= [1], header= True, row_names= True,
                                responsive= False,
                                height= '400px', width= '400px', x_label= 'Weight',
                                title= "Weight's kernelized values after integration",
                                config= {
                                        'showLegend' : True,
                                        'graphOrientation' : 'vertical',
                                        'segregateSamplesBy' : 'Integration'
                                        })}
                % endif
        </div>
</div>


















