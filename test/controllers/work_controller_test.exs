defmodule TimeKeeper.WorkControllerTest do
  use TimeKeeper.ConnCase

  alias TimeKeeper.Work
  @valid_attrs %{complete: true}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, work_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing work"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, work_path(conn, :new)
    assert html_response(conn, 200) =~ "New work"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, work_path(conn, :create), work: @valid_attrs
    assert redirected_to(conn) == work_path(conn, :index)
    assert Repo.get_by(Work, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, work_path(conn, :create), work: @invalid_attrs
    assert html_response(conn, 200) =~ "New work"
  end

  test "shows chosen resource", %{conn: conn} do
    work = Repo.insert! %Work{}
    conn = get conn, work_path(conn, :show, work)
    assert html_response(conn, 200) =~ "Show work"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, work_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    work = Repo.insert! %Work{}
    conn = get conn, work_path(conn, :edit, work)
    assert html_response(conn, 200) =~ "Edit work"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    work = Repo.insert! %Work{}
    conn = put conn, work_path(conn, :update, work), work: @valid_attrs
    assert redirected_to(conn) == work_path(conn, :show, work)
    assert Repo.get_by(Work, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    work = Repo.insert! %Work{}
    conn = put conn, work_path(conn, :update, work), work: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit work"
  end

  test "deletes chosen resource", %{conn: conn} do
    work = Repo.insert! %Work{}
    conn = delete conn, work_path(conn, :delete, work)
    assert redirected_to(conn) == work_path(conn, :index)
    refute Repo.get(Work, work.id)
  end
end
