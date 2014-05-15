# The majority of the Supplejack code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# Some components are third party components licensed under the GPL or MIT licenses 
# or otherwise publicly available. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

Sunspot.session = Sunspot::ResqueSessionProxy.new(Sunspot.session) unless Rails.env.test?

OriginalDismax = Sunspot::Query::Dismax

require_relative '../../../../lib/sunspot/sunspot_spellcheck'

class PatchedDismax < OriginalDismax

  def to_params
    params = super
    params[:defType] = 'edismax'
    params
  end

  def to_subquery
    query = super
    query = query.sub '{!dismax', '{!edismax'
    query
  end

end

Sunspot::Query.send :remove_const, :Dismax
Sunspot::Query::Dismax = PatchedDismax