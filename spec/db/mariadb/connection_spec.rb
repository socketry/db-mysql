# frozen_string_literal: true

# Copyright, 2020, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'db/mariadb/connection'
require 'async/rspec'

RSpec.describe DB::MariaDB::Connection do
	include_context Async::RSpec::Reactor
	
	subject(:connection) {described_class.new(**CREDENTIALS)}
	
	it "should connect to local server" do
		expect(connection.status).to include("Uptime")
	ensure
		connection.close
	end
	
	it "should execute query" do
		connection.send_query("SELECT 42 AS LIFE")
		
		result = connection.next_result
		
		expect(result.to_a).to be == [[42]]
	ensure
		connection.close
	end
	
	it "can list tables" do
		connection.send_query("SELECT * FROM INFORMATION_SCHEMA.TABLES")
		
		result = connection.next_result
		
		expect(result.to_a).to_not be_empty
	ensure
		connection.close
	end
	
	it "can get current time" do
		connection.send_query("SELECT UTC_TIMESTAMP() AS NOW")
		
		result = connection.next_result
		row = result.to_a.first
		
		expect(row.first).to be_within(1).of(Time.now.utc)
	ensure
		connection.close
	end
	
	describe '#append_string' do
		it "should escape string" do
			expect(connection.append_string("Hello 'World'")).to be == "'Hello \\'World\\''"
			expect(connection.append_string('Hello "World"')).to be == "'Hello \\\"World\\\"'"
		ensure
			connection.close
		end
	end
	
	describe '#append_literal' do
		it "should escape string" do
			expect(connection.append_literal("Hello World")).to be == "'Hello World'"
		ensure
			connection.close
		end
		
		it "should not escape integers" do
			expect(connection.append_literal(42)).to be == "42"
		ensure
			connection.close
		end
	end
	
	describe '#append_identifier' do
		it "should escape identifier" do
			expect(connection.append_identifier("Hello World")).to be == "`Hello World`"
		ensure
			connection.close
		end
		
		it "can handle booleans" do
			buffer = String.new
			buffer << "SELECT "
			connection.append_literal(true, buffer)
			
			connection.send_query(buffer)
			
			result = connection.next_result
			row = result.to_a.first
			
			expect(row.first).to be true
		ensure
			connection.close
		end
	end
end
