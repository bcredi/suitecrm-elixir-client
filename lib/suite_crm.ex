defmodule SuiteCrm do
  @moduledoc """
  SuiteCRM rest client for API v4.
  """

  @endpoint "/service/v4_1/rest.php"

  @doc """
  Create a new session_id using *username* and *password* params.
  """
  def login(url, username, password) do
    params = ~s({"user_auth":{"user_name":"#{username}","password":"#{password_hash(password)}"}})
    request(url, "login", params)
  end

  defp password_hash(password),
    do: :md5 |> :crypto.hash(password) |> Base.encode16(case: :lower)

  @doc """
  Create or update an entry of a crm *module*.
  """
  def set_entry(url, session_id, module_name, data \\ []) do
    params = %{
      "session" => session_id,
      "module_name" => module_name,
      "name_value_list" => data
    }

    request(url, "set_entry", params)
  end

  @doc """
  Make a request for the SuiteCRM api.

  Examples:

      iex> params = [%{"name" => "email", "value" => "mauricio@bcredi.com.br"}]
      iex> request("http://crm.bcredi.com.br", "set_entry", params)
      {:ok, %HTTPoison.Response{}}
  """
  def request(url, method, params, headers \\ []) do
    headers = [{"Content-Type", "application/x-www-form-urlencoded"} | headers]
    HTTPoison.post(url <> @endpoint, request_params(method, params), headers)
  end

  defp request_params(method, params) do
    params = [
      method: method,
      input_type: "JSON",
      response_type: "JSON",
      rest_data: params
    ]

    {:form, params}
  end
end
