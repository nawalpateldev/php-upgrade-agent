# CodeIgniter 3 to CodeIgniter 4 API Mapping

| CodeIgniter 3 | CodeIgniter 4 | Notes |
|---|---|---|
| `$this->input->post('name')` | `$this->request->getPost('name')` | Returns null if key does not exist |
| `$this->input->get('id')` | `$this->request->getGet('id')` | Returns null if key does not exist |
| `$this->input->ip_address()` | `$this->request->getIPAddress()` | Validates client IP |
| `$this->load->view('my_view', $data)` | `return view('my_view', $data)` | CI4 controllers return view response |
| `$this->session->userdata('user_id')` | `session()->get('user_id')` | Or `$this->session->get('user_id')` |
| `$this->session->set_userdata('k', 'v')`| `session()->set('k', 'v')` | |
| `$this->session->sess_destroy()` | `session()->destroy()` | |
| `$this->db->get('users')` | `$db->table('users')->get()` | Database instance via `\Config\Database::connect()` |
| `$this->db->insert('table', $data)` | `$db->table('table')->insert($data)` | |
| `$this->db->where('id', $id)` | `$db->table('table')->where('id', $id)` | |
| `$this->output->set_content_type('json')` | `return $this->response->setJSON($data)` | Native response objects |
| `redirect('users')` | `return redirect()->to('/users')` | Must be returned |
| `show_404()` | `throw \CodeIgniter\Exceptions\PageNotFoundException::forPageNotFound()` | Handled via framework exceptions |
