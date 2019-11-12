# SPDX-License-Identifier: GPL-2.0+
# Copyright (c) 2012 The Chromium OS Authors.
#

"""Tests for the dtb_platdata module

This includes unit tests for some functions and functional tests for the dtoc
tool.
"""

from __future__ import print_function

import collections
import os
import struct
import unittest

import dtb_platdata
from dtb_platdata import conv_name_to_c
from dtb_platdata import get_compat_name
from dtb_platdata import get_value
from dtb_platdata import tab_to
import fdt
import fdt_util
import test_util
import tools

our_path = os.path.dirname(os.path.realpath(__file__))


HEADER = '''/*
 * DO NOT MODIFY
 *
 * This file was generated by dtoc from a .dtb (device tree binary) file.
 */

#include <stdbool.h>
#include <linux/libfdt.h>'''

C_HEADER = '''/*
 * DO NOT MODIFY
 *
 * This file was generated by dtoc from a .dtb (device tree binary) file.
 */

#include <common.h>
#include <dm.h>
#include <dt-structs.h>
'''



def get_dtb_file(dts_fname, capture_stderr=False):
    """Compile a .dts file to a .dtb

    Args:
        dts_fname: Filename of .dts file in the current directory
        capture_stderr: True to capture and discard stderr output

    Returns:
        Filename of compiled file in output directory
    """
    return fdt_util.EnsureCompiled(os.path.join(our_path, dts_fname),
                                   capture_stderr=capture_stderr)


class TestDtoc(unittest.TestCase):
    """Tests for dtoc"""
    @classmethod
    def setUpClass(cls):
        tools.PrepareOutputDir(None)

    @classmethod
    def tearDownClass(cls):
        tools._RemoveOutputDir()

    def _WritePythonString(self, fname, data):
        """Write a string with tabs expanded as done in this Python file

        Args:
            fname: Filename to write to
            data: Raw string to convert
        """
        data = data.replace('\t', '\\t')
        with open(fname, 'w') as fd:
            fd.write(data)

    def _CheckStrings(self, expected, actual):
        """Check that a string matches its expected value

        If the strings do not match, they are written to the /tmp directory in
        the same Python format as is used here in the test. This allows for
        easy comparison and update of the tests.

        Args:
            expected: Expected string
            actual: Actual string
        """
        if expected != actual:
            self._WritePythonString('/tmp/binman.expected', expected)
            self._WritePythonString('/tmp/binman.actual', actual)
            print('Failures written to /tmp/binman.{expected,actual}')
        self.assertEquals(expected, actual)

    def test_name(self):
        """Test conversion of device tree names to C identifiers"""
        self.assertEqual('serial_at_0x12', conv_name_to_c('serial@0x12'))
        self.assertEqual('vendor_clock_frequency',
                         conv_name_to_c('vendor,clock-frequency'))
        self.assertEqual('rockchip_rk3399_sdhci_5_1',
                         conv_name_to_c('rockchip,rk3399-sdhci-5.1'))

    def test_tab_to(self):
        """Test operation of tab_to() function"""
        self.assertEqual('fred ', tab_to(0, 'fred'))
        self.assertEqual('fred\t', tab_to(1, 'fred'))
        self.assertEqual('fred was here ', tab_to(1, 'fred was here'))
        self.assertEqual('fred was here\t\t', tab_to(3, 'fred was here'))
        self.assertEqual('exactly8 ', tab_to(1, 'exactly8'))
        self.assertEqual('exactly8\t', tab_to(2, 'exactly8'))

    def test_get_value(self):
        """Test operation of get_value() function"""
        self.assertEqual('0x45',
                         get_value(fdt.TYPE_INT, struct.pack('>I', 0x45)))
        self.assertEqual('0x45',
                         get_value(fdt.TYPE_BYTE, struct.pack('<I', 0x45)))
        self.assertEqual('0x0',
                         get_value(fdt.TYPE_BYTE, struct.pack('>I', 0x45)))
        self.assertEqual('"test"', get_value(fdt.TYPE_STRING, 'test'))
        self.assertEqual('true', get_value(fdt.TYPE_BOOL, None))

    def test_get_compat_name(self):
        """Test operation of get_compat_name() function"""
        Prop = collections.namedtuple('Prop', ['value'])
        Node = collections.namedtuple('Node', ['props'])

        prop = Prop(['rockchip,rk3399-sdhci-5.1', 'arasan,sdhci-5.1'])
        node = Node({'compatible': prop})
        self.assertEqual(('rockchip_rk3399_sdhci_5_1', ['arasan_sdhci_5_1']),
                         get_compat_name(node))

        prop = Prop(['rockchip,rk3399-sdhci-5.1'])
        node = Node({'compatible': prop})
        self.assertEqual(('rockchip_rk3399_sdhci_5_1', []),
                         get_compat_name(node))

        prop = Prop(['rockchip,rk3399-sdhci-5.1', 'arasan,sdhci-5.1', 'third'])
        node = Node({'compatible': prop})
        self.assertEqual(('rockchip_rk3399_sdhci_5_1',
                          ['arasan_sdhci_5_1', 'third']),
                         get_compat_name(node))

    def test_empty_file(self):
        """Test output from a device tree file with no nodes"""
        dtb_file = get_dtb_file('dtoc_test_empty.dts')
        output = tools.GetOutputFilename('output')
        dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        with open(output) as infile:
            lines = infile.read().splitlines()
        self.assertEqual(HEADER.splitlines(), lines)

        dtb_platdata.run_steps(['platdata'], dtb_file, False, output)
        with open(output) as infile:
            lines = infile.read().splitlines()
        self.assertEqual(C_HEADER.splitlines() + [''], lines)

    def test_simple(self):
        """Test output from some simple nodes with various types of data"""
        dtb_file = get_dtb_file('dtoc_test_simple.dts')
        output = tools.GetOutputFilename('output')
        dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(HEADER + '''
struct dtd_sandbox_i2c_test {
};
struct dtd_sandbox_pmic_test {
\tbool\t\tlow_power;
\tfdt64_t\t\treg[2];
};
struct dtd_sandbox_spl_test {
\tbool\t\tboolval;
\tunsigned char\tbytearray[3];
\tunsigned char\tbyteval;
\tfdt32_t\t\tintarray[4];
\tfdt32_t\t\tintval;
\tunsigned char\tlongbytearray[9];
\tunsigned char\tnotstring[5];
\tconst char *\tstringarray[3];
\tconst char *\tstringval;
};
struct dtd_sandbox_spl_test_2 {
};
''', data)

        dtb_platdata.run_steps(['platdata'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(C_HEADER + '''
static const struct dtd_sandbox_spl_test dtv_spl_test = {
\t.boolval\t\t= true,
\t.bytearray\t\t= {0x6, 0x0, 0x0},
\t.byteval\t\t= 0x5,
\t.intarray\t\t= {0x2, 0x3, 0x4, 0x0},
\t.intval\t\t\t= 0x1,
\t.longbytearray\t\t= {0x9, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf, 0x10,
\t\t0x11},
\t.notstring\t\t= {0x20, 0x21, 0x22, 0x10, 0x0},
\t.stringarray\t\t= {"multi-word", "message", ""},
\t.stringval\t\t= "message",
};
U_BOOT_DEVICE(spl_test) = {
\t.name\t\t= "sandbox_spl_test",
\t.platdata\t= &dtv_spl_test,
\t.platdata_size\t= sizeof(dtv_spl_test),
};

static const struct dtd_sandbox_spl_test dtv_spl_test2 = {
\t.bytearray\t\t= {0x1, 0x23, 0x34},
\t.byteval\t\t= 0x8,
\t.intarray\t\t= {0x5, 0x0, 0x0, 0x0},
\t.intval\t\t\t= 0x3,
\t.longbytearray\t\t= {0x9, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
\t\t0x0},
\t.stringarray\t\t= {"another", "multi-word", "message"},
\t.stringval\t\t= "message2",
};
U_BOOT_DEVICE(spl_test2) = {
\t.name\t\t= "sandbox_spl_test",
\t.platdata\t= &dtv_spl_test2,
\t.platdata_size\t= sizeof(dtv_spl_test2),
};

static const struct dtd_sandbox_spl_test dtv_spl_test3 = {
\t.stringarray\t\t= {"one", "", ""},
};
U_BOOT_DEVICE(spl_test3) = {
\t.name\t\t= "sandbox_spl_test",
\t.platdata\t= &dtv_spl_test3,
\t.platdata_size\t= sizeof(dtv_spl_test3),
};

static const struct dtd_sandbox_spl_test_2 dtv_spl_test4 = {
};
U_BOOT_DEVICE(spl_test4) = {
\t.name\t\t= "sandbox_spl_test_2",
\t.platdata\t= &dtv_spl_test4,
\t.platdata_size\t= sizeof(dtv_spl_test4),
};

static const struct dtd_sandbox_i2c_test dtv_i2c_at_0 = {
};
U_BOOT_DEVICE(i2c_at_0) = {
\t.name\t\t= "sandbox_i2c_test",
\t.platdata\t= &dtv_i2c_at_0,
\t.platdata_size\t= sizeof(dtv_i2c_at_0),
};

static const struct dtd_sandbox_pmic_test dtv_pmic_at_9 = {
\t.low_power\t\t= true,
\t.reg\t\t\t= {0x9, 0x0},
};
U_BOOT_DEVICE(pmic_at_9) = {
\t.name\t\t= "sandbox_pmic_test",
\t.platdata\t= &dtv_pmic_at_9,
\t.platdata_size\t= sizeof(dtv_pmic_at_9),
};

''', data)

    def test_phandle(self):
        """Test output from a node containing a phandle reference"""
        dtb_file = get_dtb_file('dtoc_test_phandle.dts')
        output = tools.GetOutputFilename('output')
        dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(HEADER + '''
struct dtd_source {
\tstruct phandle_2_arg clocks[4];
};
struct dtd_target {
\tfdt32_t\t\tintval;
};
''', data)

        dtb_platdata.run_steps(['platdata'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(C_HEADER + '''
static const struct dtd_target dtv_phandle_target = {
\t.intval\t\t\t= 0x0,
};
U_BOOT_DEVICE(phandle_target) = {
\t.name\t\t= "target",
\t.platdata\t= &dtv_phandle_target,
\t.platdata_size\t= sizeof(dtv_phandle_target),
};

static const struct dtd_target dtv_phandle2_target = {
\t.intval\t\t\t= 0x1,
};
U_BOOT_DEVICE(phandle2_target) = {
\t.name\t\t= "target",
\t.platdata\t= &dtv_phandle2_target,
\t.platdata_size\t= sizeof(dtv_phandle2_target),
};

static const struct dtd_target dtv_phandle3_target = {
\t.intval\t\t\t= 0x2,
};
U_BOOT_DEVICE(phandle3_target) = {
\t.name\t\t= "target",
\t.platdata\t= &dtv_phandle3_target,
\t.platdata_size\t= sizeof(dtv_phandle3_target),
};

static const struct dtd_source dtv_phandle_source = {
\t.clocks\t\t\t= {
\t\t\t{&dtv_phandle_target, {}},
\t\t\t{&dtv_phandle2_target, {11}},
\t\t\t{&dtv_phandle3_target, {12, 13}},
\t\t\t{&dtv_phandle_target, {}},},
};
U_BOOT_DEVICE(phandle_source) = {
\t.name\t\t= "source",
\t.platdata\t= &dtv_phandle_source,
\t.platdata_size\t= sizeof(dtv_phandle_source),
};

static const struct dtd_source dtv_phandle_source2 = {
\t.clocks\t\t\t= {
\t\t\t{&dtv_phandle_target, {}},},
};
U_BOOT_DEVICE(phandle_source2) = {
\t.name\t\t= "source",
\t.platdata\t= &dtv_phandle_source2,
\t.platdata_size\t= sizeof(dtv_phandle_source2),
};

''', data)

    def test_phandle_single(self):
        """Test output from a node containing a phandle reference"""
        dtb_file = get_dtb_file('dtoc_test_phandle_single.dts')
        output = tools.GetOutputFilename('output')
        dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(HEADER + '''
struct dtd_source {
\tstruct phandle_0_arg clocks[1];
};
struct dtd_target {
\tfdt32_t\t\tintval;
};
''', data)

    def test_phandle_reorder(self):
        """Test that phandle targets are generated before their references"""
        dtb_file = get_dtb_file('dtoc_test_phandle_reorder.dts')
        output = tools.GetOutputFilename('output')
        dtb_platdata.run_steps(['platdata'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(C_HEADER + '''
static const struct dtd_target dtv_phandle_target = {
};
U_BOOT_DEVICE(phandle_target) = {
\t.name\t\t= "target",
\t.platdata\t= &dtv_phandle_target,
\t.platdata_size\t= sizeof(dtv_phandle_target),
};

static const struct dtd_source dtv_phandle_source2 = {
\t.clocks\t\t\t= {
\t\t\t{&dtv_phandle_target, {}},},
};
U_BOOT_DEVICE(phandle_source2) = {
\t.name\t\t= "source",
\t.platdata\t= &dtv_phandle_source2,
\t.platdata_size\t= sizeof(dtv_phandle_source2),
};

''', data)

    def test_phandle_bad(self):
        """Test a node containing an invalid phandle fails"""
        dtb_file = get_dtb_file('dtoc_test_phandle_bad.dts',
                                capture_stderr=True)
        output = tools.GetOutputFilename('output')
        with self.assertRaises(ValueError) as e:
            dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        self.assertIn("Cannot parse 'clocks' in node 'phandle-source'",
                      str(e.exception))

    def test_phandle_bad2(self):
        """Test a phandle target missing its #*-cells property"""
        dtb_file = get_dtb_file('dtoc_test_phandle_bad2.dts',
                                capture_stderr=True)
        output = tools.GetOutputFilename('output')
        with self.assertRaises(ValueError) as e:
            dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        self.assertIn("Node 'phandle-target' has no '#clock-cells' property",
                      str(e.exception))

    def test_aliases(self):
        """Test output from a node with multiple compatible strings"""
        dtb_file = get_dtb_file('dtoc_test_aliases.dts')
        output = tools.GetOutputFilename('output')
        dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(HEADER + '''
struct dtd_compat1 {
\tfdt32_t\t\tintval;
};
#define dtd_compat2_1_fred dtd_compat1
#define dtd_compat3 dtd_compat1
''', data)

        dtb_platdata.run_steps(['platdata'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(C_HEADER + '''
static const struct dtd_compat1 dtv_spl_test = {
\t.intval\t\t\t= 0x1,
};
U_BOOT_DEVICE(spl_test) = {
\t.name\t\t= "compat1",
\t.platdata\t= &dtv_spl_test,
\t.platdata_size\t= sizeof(dtv_spl_test),
};

''', data)

    def test_addresses64(self):
        """Test output from a node with a 'reg' property with na=2, ns=2"""
        dtb_file = get_dtb_file('dtoc_test_addr64.dts')
        output = tools.GetOutputFilename('output')
        dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(HEADER + '''
struct dtd_test1 {
\tfdt64_t\t\treg[2];
};
struct dtd_test2 {
\tfdt64_t\t\treg[2];
};
struct dtd_test3 {
\tfdt64_t\t\treg[4];
};
''', data)

        dtb_platdata.run_steps(['platdata'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(C_HEADER + '''
static const struct dtd_test1 dtv_test1 = {
\t.reg\t\t\t= {0x1234, 0x5678},
};
U_BOOT_DEVICE(test1) = {
\t.name\t\t= "test1",
\t.platdata\t= &dtv_test1,
\t.platdata_size\t= sizeof(dtv_test1),
};

static const struct dtd_test2 dtv_test2 = {
\t.reg\t\t\t= {0x1234567890123456, 0x9876543210987654},
};
U_BOOT_DEVICE(test2) = {
\t.name\t\t= "test2",
\t.platdata\t= &dtv_test2,
\t.platdata_size\t= sizeof(dtv_test2),
};

static const struct dtd_test3 dtv_test3 = {
\t.reg\t\t\t= {0x1234567890123456, 0x9876543210987654, 0x2, 0x3},
};
U_BOOT_DEVICE(test3) = {
\t.name\t\t= "test3",
\t.platdata\t= &dtv_test3,
\t.platdata_size\t= sizeof(dtv_test3),
};

''', data)

    def test_addresses32(self):
        """Test output from a node with a 'reg' property with na=1, ns=1"""
        dtb_file = get_dtb_file('dtoc_test_addr32.dts')
        output = tools.GetOutputFilename('output')
        dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(HEADER + '''
struct dtd_test1 {
\tfdt32_t\t\treg[2];
};
struct dtd_test2 {
\tfdt32_t\t\treg[4];
};
''', data)

        dtb_platdata.run_steps(['platdata'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(C_HEADER + '''
static const struct dtd_test1 dtv_test1 = {
\t.reg\t\t\t= {0x1234, 0x5678},
};
U_BOOT_DEVICE(test1) = {
\t.name\t\t= "test1",
\t.platdata\t= &dtv_test1,
\t.platdata_size\t= sizeof(dtv_test1),
};

static const struct dtd_test2 dtv_test2 = {
\t.reg\t\t\t= {0x12345678, 0x98765432, 0x2, 0x3},
};
U_BOOT_DEVICE(test2) = {
\t.name\t\t= "test2",
\t.platdata\t= &dtv_test2,
\t.platdata_size\t= sizeof(dtv_test2),
};

''', data)

    def test_addresses64_32(self):
        """Test output from a node with a 'reg' property with na=2, ns=1"""
        dtb_file = get_dtb_file('dtoc_test_addr64_32.dts')
        output = tools.GetOutputFilename('output')
        dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(HEADER + '''
struct dtd_test1 {
\tfdt64_t\t\treg[2];
};
struct dtd_test2 {
\tfdt64_t\t\treg[2];
};
struct dtd_test3 {
\tfdt64_t\t\treg[4];
};
''', data)

        dtb_platdata.run_steps(['platdata'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(C_HEADER + '''
static const struct dtd_test1 dtv_test1 = {
\t.reg\t\t\t= {0x123400000000, 0x5678},
};
U_BOOT_DEVICE(test1) = {
\t.name\t\t= "test1",
\t.platdata\t= &dtv_test1,
\t.platdata_size\t= sizeof(dtv_test1),
};

static const struct dtd_test2 dtv_test2 = {
\t.reg\t\t\t= {0x1234567890123456, 0x98765432},
};
U_BOOT_DEVICE(test2) = {
\t.name\t\t= "test2",
\t.platdata\t= &dtv_test2,
\t.platdata_size\t= sizeof(dtv_test2),
};

static const struct dtd_test3 dtv_test3 = {
\t.reg\t\t\t= {0x1234567890123456, 0x98765432, 0x2, 0x3},
};
U_BOOT_DEVICE(test3) = {
\t.name\t\t= "test3",
\t.platdata\t= &dtv_test3,
\t.platdata_size\t= sizeof(dtv_test3),
};

''', data)

    def test_addresses32_64(self):
        """Test output from a node with a 'reg' property with na=1, ns=2"""
        dtb_file = get_dtb_file('dtoc_test_addr32_64.dts')
        output = tools.GetOutputFilename('output')
        dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(HEADER + '''
struct dtd_test1 {
\tfdt64_t\t\treg[2];
};
struct dtd_test2 {
\tfdt64_t\t\treg[2];
};
struct dtd_test3 {
\tfdt64_t\t\treg[4];
};
''', data)

        dtb_platdata.run_steps(['platdata'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(C_HEADER + '''
static const struct dtd_test1 dtv_test1 = {
\t.reg\t\t\t= {0x1234, 0x567800000000},
};
U_BOOT_DEVICE(test1) = {
\t.name\t\t= "test1",
\t.platdata\t= &dtv_test1,
\t.platdata_size\t= sizeof(dtv_test1),
};

static const struct dtd_test2 dtv_test2 = {
\t.reg\t\t\t= {0x12345678, 0x9876543210987654},
};
U_BOOT_DEVICE(test2) = {
\t.name\t\t= "test2",
\t.platdata\t= &dtv_test2,
\t.platdata_size\t= sizeof(dtv_test2),
};

static const struct dtd_test3 dtv_test3 = {
\t.reg\t\t\t= {0x12345678, 0x9876543210987654, 0x2, 0x3},
};
U_BOOT_DEVICE(test3) = {
\t.name\t\t= "test3",
\t.platdata\t= &dtv_test3,
\t.platdata_size\t= sizeof(dtv_test3),
};

''', data)

    def test_bad_reg(self):
        """Test that a reg property with an invalid type generates an error"""
        # Capture stderr since dtc will emit warnings for this file
        dtb_file = get_dtb_file('dtoc_test_bad_reg.dts', capture_stderr=True)
        output = tools.GetOutputFilename('output')
        with self.assertRaises(ValueError) as e:
            dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        self.assertIn("Node 'spl-test' reg property is not an int",
                      str(e.exception))

    def test_bad_reg2(self):
        """Test that a reg property with an invalid cell count is detected"""
        # Capture stderr since dtc will emit warnings for this file
        dtb_file = get_dtb_file('dtoc_test_bad_reg2.dts', capture_stderr=True)
        output = tools.GetOutputFilename('output')
        with self.assertRaises(ValueError) as e:
            dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        self.assertIn("Node 'spl-test' reg property has 3 cells which is not a multiple of na + ns = 1 + 1)",
                      str(e.exception))

    def test_add_prop(self):
        """Test that a subequent node can add a new property to a struct"""
        dtb_file = get_dtb_file('dtoc_test_add_prop.dts')
        output = tools.GetOutputFilename('output')
        dtb_platdata.run_steps(['struct'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(HEADER + '''
struct dtd_sandbox_spl_test {
\tfdt32_t\t\tintarray;
\tfdt32_t\t\tintval;
};
''', data)

        dtb_platdata.run_steps(['platdata'], dtb_file, False, output)
        with open(output) as infile:
            data = infile.read()
        self._CheckStrings(C_HEADER + '''
static const struct dtd_sandbox_spl_test dtv_spl_test = {
\t.intval\t\t\t= 0x1,
};
U_BOOT_DEVICE(spl_test) = {
\t.name\t\t= "sandbox_spl_test",
\t.platdata\t= &dtv_spl_test,
\t.platdata_size\t= sizeof(dtv_spl_test),
};

static const struct dtd_sandbox_spl_test dtv_spl_test2 = {
\t.intarray\t\t= 0x5,
};
U_BOOT_DEVICE(spl_test2) = {
\t.name\t\t= "sandbox_spl_test",
\t.platdata\t= &dtv_spl_test2,
\t.platdata_size\t= sizeof(dtv_spl_test2),
};

''', data)

    def testStdout(self):
        """Test output to stdout"""
        dtb_file = get_dtb_file('dtoc_test_simple.dts')
        with test_util.capture_sys_output() as (stdout, stderr):
            dtb_platdata.run_steps(['struct'], dtb_file, False, '-')

    def testNoCommand(self):
        """Test running dtoc without a command"""
        with self.assertRaises(ValueError) as e:
            dtb_platdata.run_steps([], '', False, '')
        self.assertIn("Please specify a command: struct, platdata",
                      str(e.exception))

    def testBadCommand(self):
        """Test running dtoc with an invalid command"""
        dtb_file = get_dtb_file('dtoc_test_simple.dts')
        output = tools.GetOutputFilename('output')
        with self.assertRaises(ValueError) as e:
            dtb_platdata.run_steps(['invalid-cmd'], dtb_file, False, output)
        self.assertIn("Unknown command 'invalid-cmd': (use: struct, platdata)",
                      str(e.exception))
