#!/usr/bin/env python

import numpy as np
import argparse

def get_stats(data):
	stats = {}
	stats['average'] = np.mean(data)
	stats['variance'] = np.var(data)
	stats['standardDeviation'] = np.std(data)
	stats['max'] = np.max(data)
	stats['min'] = np.min(data)
	stats['count'] = len(data)
	stats['countNonZero'] = np.count_nonzero(data)
	stats['q1'], stats['median'], stats['q3'] = np.percentile(data, [25, 50, 75])
	return stats

def report_stats(stats):
	report_stats = []
	report_stats.append(['Elements', stats['count']])
	report_stats.append(['Elements Non Zero', stats['countNonZero']])
	report_stats.append(['Non Zero Density', stats['countNonZero'] / stats['count']])
	report_stats.append(['Max', stats['max']])
	report_stats.append(['Min', stats['min']])
	report_stats.append(['Average', stats['average']])
	report_stats.append(['Variance', stats['variance']])
	report_stats.append(['Standard Deviation', stats['standardDeviation']])
	report_stats.append(['Q1', stats['q1']])
	report_stats.append(['Median', stats['median']])
	report_stats.append(['Q3', stats['q3']])
	return report_stats

def extract_data(lst_file):
	with open(lst_file, 'r') as f:
		data = [float(line.strip()) for line in f]
	return data


########################### OPTPARSE ########################
#############################################################

parser = argparse.ArgumentParser(description='Calculate statistics of data in a file')
parser.add_argument('-d', '--data_file', help='The path to the data file', required=True)
options = parser.parse_args()

####################################################################

path2data = options.data_file

data = extract_data(path2data)
stats = get_stats(data)
for stat in report_stats(stats):
	print('\t'.join(map(str, stat)))