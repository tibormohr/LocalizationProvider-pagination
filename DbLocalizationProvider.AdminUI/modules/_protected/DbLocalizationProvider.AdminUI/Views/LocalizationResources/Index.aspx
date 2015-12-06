﻿<%@ Page Language="C#" Inherits="System.Web.Mvc.ViewPage<TechFellow.DbLocalizationProvider.AdminUI.LocalizationResourceViewModel>" %>
<%@ Assembly Name="EPiServer.Shell.UI" %>


<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Localization Resources</title>

    <link href="//netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css" rel="stylesheet">
    <link href="//cdnjs.cloudflare.com/ajax/libs/x-editable/1.5.0/bootstrap3-editable/css/bootstrap-editable.css" rel="stylesheet"/>

    <%= Page.ClientResources("ShellCore") %>
    <%= Page.ClientResources("ShellCoreLightTheme") %>

    <script src="//code.jquery.com/jquery-2.0.3.min.js"></script>
    <script src="//netdna.bootstrapcdn.com/bootstrap/3.0.0/js/bootstrap.min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/x-editable/1.5.0/bootstrap3-editable/js/bootstrap-editable.min.js"></script>

    <style type="text/css">
        table.table > tbody > tr > td {
            height: 30px;
            vertical-align: middle;
        }

        .glyphicon { font-size: 2rem; }
    </style>
</head>
<body>
<div class="epi-contentContainer epi-padding">
    <div class="epi-contentArea epi-paddingHorizontal">
        <h1 class="EP-prefix">Localization Resources</h1>
        <div class="epi-paddingVertical">

            <form id="resourceFilterForm">
                <div class="form-group">
                    <div class="input-group">
                        <input type="search" value="" class="form-control" placeholder="Enter Search Query"/>
                        <span class="input-group-btn">
                            <button class="btn btn-default" type="submit">
                                <span class="glyphicon glyphicon-search"></span>
                                <span class="sr-only">Search</span>
                            </button>
                        </span>
                    </div>
                </div>
            </form>

            <%--<form>
                <div class="form-group">
                    <div class="input-group">
                        <a class="btn btn-blue btn-primary" href="#" id="newResource">+ Create new resource</a>
                    </div>
                </div>
            </form>--%>

            <table class="table table-bordered table-striped" id="resourceList" style="clear: both">
                <thead>
                <tr>
                    <th>Resource Key</th>
                    <% foreach (var language in Model.Languages)
                       { %>
                    <th><%= language.EnglishName %></th>
                    <% } %>
                </tr>
                </thead>
                <tbody>

                <tr class="hidden new-resource-form">
                    <td>
                        <div class="form-inline">
                            <button class="btn btn-default btn-primary" id="saveResource">
                                <span href="#" class="glyphicon glyphicon-ok"></span>
                            </button>
                            <button class="btn" id="cancelNewResource">
                                <span href="#" class="glyphicon glyphicon-remove"></span>
                            </button>
                            <input class="form-control" id="resourceKey" placeholder="Resource Key" style="width: 50%"/>
                        </div>
                    </td>
                    <% foreach (var language in Model.Languages)
                       { %>
                    <td>
                        <input class="form-control resource-translation" id="<%= language %>"/>
                    </td>
                    <% } %>
                </tr>

                <%foreach (var resource in Model.Resources)
                {%>
                <tr class="localization resource">
                    <td><%= resource.Key%></td>
                    <% foreach (var localizedResource in Model.Resources.Where(r => r.Key == resource.Key))
                    {
                    foreach (var language in Model.Languages)
                    {
                    var z = localizedResource.Value.FirstOrDefault(l => l.SourceCulture.Name == language.Name);
                    if (z != null)
                    {%>
                    <td>
                        <a href="#" id="<%=language.Name %>" data-type="text" data-pk="<%= resource.Key %>" data-title="Enter translation"><%= z.Value %></a>
                    </td>
                    <%}
                    }
                    }%>
                </tr>
                <%}%>
                </tbody>
            </table>


            <script type="text/javascript">
                $(function() {
                    $.fn.editable.defaults.mode = 'popup';
                    $('.localization a').editable({
                        url: '<%= Url.Action("Update")%>'
                    });

                    var $filterForm = $('#resourceFilterForm'),
                        $filterInput = $filterForm.find('.form-control:first-child'),
                        $resourceList = $('#resourceList'),
                        $resourceItem = $resourceList.find('.resource');

                    function runFilter() {
                        var query = $filterInput.val();

                        if (query.length === 0) {
                            $resourceItem.removeClass('hidden');
                            return;
                        }

                        $resourceItem.each(function() {
                            var $item = $(this);
                            if ($item.text().search(new RegExp(query, 'i')) > -1) {
                                $item.removeClass('hidden');
                            } else {
                                $item.addClass('hidden');
                            }
                        });
                    }

                    var t;
                    $filterInput.on('input', function() {
                        clearTimeout(t);
                        t = setTimeout(runFilter, 500);
                    });
                    $filterForm.on('submit', function(e) {
                        e.preventDefault();
                        clearTimeout(t);
                        runFilter();
                    });

                    $('#newResource').on('click', function() {
                        $('.new-resource-form').removeClass('hidden');
                        $('#resourceKey').focus();
                    });

                    $('#cancelNewResource').on('click', function() {
                        $('.new-resource-form').addClass('hidden');
                    });

                    $('#saveResource').on('click', function() {
                        var $form = $('.new-resource-form'),
                            $resourceKey = $form.find('#resourceKey').val();

                        if ($resourceKey.length == 0) {
                            alert('Fill resource key');
                            return;
                        }

                        $.ajax({
                            url: '@Url.Action("Create")',
                            method: 'POST',
                            data: 'pk=' + $resourceKey
                        }).success(function() {
                            var $translations = $form.find('.resource-translation');

                            var requests = [];

                            $.map($translations, function(el) {
                                var $el = $(el);
                                requests.push($.ajax({
                                    url: '<%= Url.Action("Update")%>',
                                    method: 'POST',
                                    data: 'pk=' + $resourceKey + '&name=' + el.id + '&value=' + $el.val()
                                }));
                            });

                            $.when(requests).then(function() {
                                setTimeout(function() {
                                    location.reload();
                                }, 1000);
                            });
                        });
                    });
                })
            </script>

        </div>
    </div>
</div>
</body>
</html>