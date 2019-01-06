import pytest
import pynvim
from nvim_fixtures import get_nvim


class TestDemoPluginFunctions(object):

    """
    TestDemoPluginFunctions.
    This test suite tests all demo-plugin funtions by leveraging pynvim
    official client (since it's super stable).
    """

    def test_rpc_connection(self, get_nvim):
        """Test pynvim socket RPC connection."""
        assert get_nvim

    def test_greet(self, get_nvim):
        """Test demo-plugin Greet function."""
        nvim = get_nvim
        res = nvim.command_output("echo Greet('D')")
        assert res == "Hello D"

    def test_greet_wrong_args(self, get_nvim):
        """Test demo-plugin Greet function."""
        nvim = get_nvim
        with pytest.raises(pynvim.api.nvim.NvimError) as exc:
            nvim.command_output("echo Greet(1)")
            assert "Wrong function argument types" in str(exc.value)

    def test_sum_begin_to_end(self, get_nvim):
        """Test demo-plugin SumBeginToEnd function."""
        nvim = get_nvim
        res = nvim.command_output("echo SumBeginToEnd(0, 10)")
        assert res == str(sum(range(0, 10)))

    def test_set_var_value_sync(self, get_nvim):
        """Test demo-plugin SetVarValueSync function."""
        nvim = get_nvim
        nvim.command("call SetVarValueSync(555)")
        res = nvim.command_output("echo g:test_var_value")
        assert res == "555"

    def test_set_var_value_async(self, get_nvim):
        """Test demo-plugin SetVarValueAsync function."""
        nvim = get_nvim
        nvim.command("call SetVarValueAsync(56)")
        res = nvim.command_output("echo g:testasync_var_value")
        assert res == "56"
