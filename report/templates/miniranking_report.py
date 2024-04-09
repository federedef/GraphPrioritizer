<%
        import pandas as pd
        def get_size(var_name, groupby = ['annot_Embedding','annot','Embedding','group_seed'], value = 'rank'):
                df = pd.DataFrame(plotter.hash_vars[var_name][1:], columns = plotter.hash_vars[var_name][0])
                len_by_attributes = df.groupby(groupby)[value].size().reset_index()
                len_by_attributes = len_by_attributes.sort_values(by=value)
                col_names = plotter.hash_vars[var_name][0]
                return [col_names] + len_by_attributes.values.tolist()

        plotter.hash_vars["control_pos"] = get_size("control_pos", groupby=["Seed Name"], value = "Genes")
%>
<div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
        % if plotter.hash_vars.get('control_pos') is not None:
                        ${plotter.barplot(id='control_pos', fields= [0,1], header= True, height= '400px',colorScale=True, width= '400px', x_label= 'Number of genes by seed', title= "")}
        % endif
</div>