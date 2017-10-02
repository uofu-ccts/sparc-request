# Copyright © 2011-2017 MUSC Foundation for Research Development
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

class IdentitiesController < ApplicationController

  def find_or_create
    @identity = Identity.find_or_create(params[:term])
    @can_edit = false
    project_role_params = params[session[:protocol_type].to_sym][:project_roles_attributes][@identity.id.to_s] rescue nil
    if project_role_params
      project_role_params.delete '_destroy'
      id = project_role_params.delete 'id'

      if id.blank?
        @project_role = ProjectRole.new project_role_params
      else
        @project_role = ProjectRole.find id
        @project_role.project_rights = project_role_params[:project_rights]
      end

      @can_edit = true
    else
      @project_role = ProjectRole.new
    end
    render :show
  end

  def show
    @identity = Identity.find params[:id]
    @can_edit = false
    project_role_params = params[session[:protocol_type].to_sym][:project_roles_attributes][@identity.id.to_s] rescue nil
    if project_role_params
      project_role_params.delete '_destroy'
      id = project_role_params.delete 'id'

      if id.blank?
        @project_role = ProjectRole.new project_role_params
      else
        @project_role = ProjectRole.find id
        @project_role.project_rights = project_role_params[:project_rights]
      end

      @can_edit = true
    else
      @project_role = ProjectRole.new
    end
  end


  def approve_account
    @identity = Identity.find params[:id]
    @identity.update_attribute(:approved, true)
    Notifier.account_status_change(@identity, true).deliver unless @identity.email.blank?
  end

  def disapprove_account
    @identity = Identity.find params[:id]
    @identity.update_attribute(:approved, false)
    Notifier.account_status_change(@identity, false).deliver unless @identity.email.blank?
  end
end
