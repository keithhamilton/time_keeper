defmodule TimeKeeper.WorkTest do
  use TimeKeeper.ModelCase

  alias TimeKeeper.Work

  @valid_attrs %{complete: true}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Work.changeset(%Work{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Work.changeset(%Work{}, @invalid_attrs)
    refute changeset.valid?
  end
end
