defmodule TimeKeeper.ButtonTest do
  use TimeKeeper.ModelCase

  alias TimeKeeper.Button

  @valid_attrs %{serial_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Button.changeset(%Button{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Button.changeset(%Button{}, @invalid_attrs)
    refute changeset.valid?
  end
end
