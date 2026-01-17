defmodule TelemedCoreTest do
  use ExUnit.Case
  doctest TelemedCore

  test "greets the world" do
    assert TelemedCore.hello() == :world
  end
end
