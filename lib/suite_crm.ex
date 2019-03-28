defmodule SuiteCrm do
  @moduledoc """
  SuiteCRM rest client for API v4.
  """

  @endpoint "/service/v4_1/rest.php"

  @doc """
  Create a new session_id using *username* and *password* params.
  """
  def login(url, username, password, options \\ []) do
    params = %{
      user_auth: %{
        user_name: username,
        password: password_hash(password)
      }
    }

    request(url, "login", params, nil, [], options)
  end

  defp password_hash(password),
    do: :md5 |> :crypto.hash(password) |> Base.encode16(case: :lower)

  @doc """
  Create or update an entry of a crm *module*.
  """
  def set_entry(url, session_id, module_name, data \\ %{}, options \\ []) do
    params = %{
      name_value_list: build_name_value_list(data),
      module_name: module_name
    }

    request(url, "set_entry", params, session_id, [], options)
  end

  defp build_name_value_list(data) do
    data
    |> Enum.map(fn {name, value} -> %{name => %{name: name, value: value}} end)
    |> Enum.reduce(%{}, fn acc, x -> Map.merge(acc, x) end)
  end

  @doc """
  Get an entry of a crm *module*.
  """
  def get_entry(url, session_id, module_name, id, select_fields \\ [], options \\ []) do
    params = %{
      module_name: module_name,
      id: id,
      select_fields: select_fields
    }

    request(url, "get_entry", params, session_id, [], options)
  end

  @doc """
  Make a request for the SuiteCRM api.

  Examples:

      iex> values = %{email1: %{name: "email1", value: "mauricio@bcredi.com.br"}}
      iex> params = %{session: "123", name_value_list: values}
      iex> request("http://crm.bcredi.com.br", "set_entry", params, "some-session-id")
      {:ok, %HTTPoison.Response{}}
  """
  def request(url, method, params, session \\ nil, headers \\ [], options \\ []) do
    headers = [{"Content-Type", "application/x-www-form-urlencoded"} | headers]
    HTTPoison.post(url <> @endpoint, request_params(method, params, session), headers, options)
  end

  defp request_params(method, params, session)

  defp request_params(method, params, nil) do
    params = [
      method: method,
      input_type: "JSON",
      response_type: "JSON",
      rest_data: Jason.encode!(params)
    ]

    {:form, params}
  end

  defp request_params("get_entry" = method, params, session) do
    data = ~s({
      "session":"#{session}",
      "module_name":"#{params[:module_name]}",
      "id":"#{params[:id]}",
      "link_name_to_fields_array":[],
      "select_fields":#{Jason.encode!(params[:select_fields])}
    })

    params = [
      method: method,
      input_type: "JSON",
      response_type: "JSON",
      rest_data: data
    ]

    {:form, params}
  end

  defp request_params(method, params, session) do
    data = params |> Jason.encode!() |> build_authenticated_rest_data(session)

    params = [
      method: method,
      input_type: "JSON",
      response_type: "JSON",
      rest_data: data
    ]

    {:form, params}
  end

  # SuiteCRM api params require order
  # (session need to be sent before any other param)
  #
  # Split at first char `{` to allow us concat the session in the beggining
  defp build_authenticated_rest_data("{" <> data, session) do
    ~s({"session":"#{session}", ) <> data
  end
end
