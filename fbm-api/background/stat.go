package main

import (
	"github.com/prometheus/client_golang/prometheus"
)

var (
	totalProcessedCounterVec = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "fbm",
			Subsystem: "jobs",
			Name:      "processed_total",
			Help:      "Total number of jobs processed by the workers",
		},
		[]string{"type"},
	)

	totalSuccessfulCounterVec = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "fbm",
			Subsystem: "jobs",
			Name:      "processed_successful_total",
			Help:      "Total number of successful jobs processed by the workers",
		},
		[]string{"type"},
	)

	totalFailedCounterVec = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "fbm",
			Subsystem: "jobs",
			Name:      "processed_failed_total",
			Help:      "Total number of failed jobs processed by the workers",
		},
		[]string{"type"},
	)

	currentProcessingGaugeVec = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Namespace: "fbm",
			Subsystem: "jobs",
			Name:      "processing_current",
			Help:      "Number of jobs are processing by the workers",
		},
		[]string{"type"},
	)

	maxProcessingGaugeVec = prometheus.NewGaugeVec(
		prometheus.GaugeOpts{
			Namespace: "fbm",
			Subsystem: "jobs",
			Name:      "processing_max",
			Help:      "Max number of jobs that can be processed by the worker",
		},
		[]string{},
	)
)

func registerMetrics() error {
	if err := prometheus.Register(totalProcessedCounterVec); err != nil {
		return err
	}

	if err := prometheus.Register(currentProcessingGaugeVec); err != nil {
		return err
	}

	if err := prometheus.Register(maxProcessingGaugeVec); err != nil {
		return err
	}

	if err := prometheus.Register(totalSuccessfulCounterVec); err != nil {
		return err
	}

	if err := prometheus.Register(totalFailedCounterVec); err != nil {
		return err
	}

	return nil
}
