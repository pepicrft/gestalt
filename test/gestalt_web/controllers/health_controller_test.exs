defmodule GestaltWeb.HealthControllerTest do
  use GestaltWeb.ConnCase, async: true

  describe "GET /api/health" do
    test "returns ok status", %{conn: conn} do
      conn = get(conn, ~p"/api/health")

      assert json_response(conn, 200) == %{"status" => "ok"}
    end
  end
end
