# Copyright 2025-2026 School of Integrated Circuits, Peking University
# SPDX-License-Identifier: Apache-2.0
#
PYTHON ?= python3
.PHONY: test extended lint clean

# Run from rtl/. Individual runners also resolve paths from their own location.
test:
	$(PYTHON) verification/run_regression.py --width 2 --out build/core
	$(PYTHON) verification/run_dco_checks.py --out build/dco
	$(PYTHON) verification/check_top_interface.py

# Additional widths and independent random data; test is a prerequisite.
extended: test
	@set -e; for width in 1 4 8 16 32 64; do \
	  $(PYTHON) verification/run_regression.py --only fp --width $$width \
	    --seed $$((260900 + width)) --out build/fp_p$$width; \
	done
	$(PYTHON) verification/run_regression.py --only int --seed 260909 --out build/int_seed260909

# Full-SoC integration diagnostic.
lint:
	$(PYTHON) verification/run_dco_checks.py --only lint --out build/fullchip

clean:
	rm -rf build
