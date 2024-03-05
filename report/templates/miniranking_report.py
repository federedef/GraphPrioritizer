<%
        def make_title(type, id, sentence):
                if type == "table":
                        key = f"tab:{id}"
                        html_title = f"<p style='text-align:center;'> <b> {type.capitalize()} {plotter.add_table(key)} </b> {sentence} </p>"
                elif type == "figure":
                        key = id
                        html_title = f"<p style='text-align:center;'> <b> {type.capitalize()} {plotter.add_figure(key)} </b> {sentence} </p>"
                return html_title
%>
<div style="overflow: hidden; display: flex; flex-direction: row; justify-content: center;">
        % if plotter.hash_vars.get('parsed_uncomb_kernel_metrics') is not None:
                        ${plotter.barplot(id='parsed_uncomb_kernel_metrics', fields= [2,6] , header= True, height= '400px', width= '400px', x_label= 'Matrix Non Zero Density (%)', var_attr= [1,2],
                                title = "(A) Individual eGSM",
                                config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'horizontal',
                                        'colorBy' : 'Embedding',
                                        "segregateSamplesBy": ["Net"],
                                        "axisTickScaleFontFactor": 0.2,
                                        'setMinX': 0,
                                        "titleFontStyle": "italic",
                                        "titleScaleFontFactor": 0.3
                                        })}
        % endif
        % if plotter.hash_vars.get('parsed_comb_kernel_metrics') is not None:
                        ${plotter.barplot(id='parsed_comb_kernel_metrics', fields= [2,6] , header= True, height= '400px', width= '400px', x_label= 'Matrix Non Zero Density (%)', var_attr= [1,2],
                                title = "(B) Integrated eGSM",
                                config = {
                                        'showLegend' : True,
                                        'graphOrientation' : 'horizontal',
                                        'colorBy' : 'Embedding',
                                        'segregateSamplesBy': "Integration",
                                        'setMinX': 0,
                                        "titleFontStyle": "italic",
                                        "titleScaleFontFactor": 0.3
                                        })}
        % endif

        ${make_title("figure","density_summ", "Summary of eGSM density")}
</div>