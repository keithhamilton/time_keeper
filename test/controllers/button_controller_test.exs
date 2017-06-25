defmodule TimeKeeper.ButtonControllerTest do
  use TimeKeeper.ConnCase

  alias TimeKeeper.Button
  @valid_attrs %{serial_id: 42}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, button_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing buttons"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, button_path(conn, :new)
    assert html_response(conn, 200) =~ "New button"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, button_path(conn, :create), button: @valid_attrs
    assert redirected_to(conn) == button_path(conn, :index)
    assert Repo.get_by(Button, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, button_path(conn, :create), button: @invalid_attrs
    assert html_response(conn, 200) =~ "New button"
  end

  test "shows chosen resource", %{conn: conn} do
    button = Repo.insert! %Button{}
    conn = get conn, button_path(conn, :show, button)
    assert html_response(conn, 200) =~ "Show button"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, button_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    button = Repo.insert! %Button{}
    conn = get conn, button_path(conn, :edit, button)
    assert html_response(conn, 200) =~ "Edit button"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    button = Repo.insert! %Button{}
    conn = put conn, button_path(conn, :update, button), button: @valid_attrs
    assert redirected_to(conn) == button_path(conn, :show, button)
    assert Repo.get_by(Button, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    button = Repo.insert! %Button{}
    conn = put conn, button_path(conn, :update, button), button: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit button"
  end

  test "deletes chosen resource", %{conn: conn} do
    button = Repo.insert! %Button{}
    conn = delete conn, button_path(conn, :delete, button)
    assert redirected_to(conn) == button_path(conn, :index)
    refute Repo.get(Button, button.id)
  end
end
