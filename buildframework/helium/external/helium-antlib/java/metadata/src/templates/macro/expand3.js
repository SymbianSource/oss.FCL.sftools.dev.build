function __ToggleNode( divNode )
{
  var cntNode = document.getElementById(divNode.id.replace(/Img(.+)/, 'Content$1'));
  
  if(!cntNode) return;
  
  if(cntNode.style.display == 'none')
  {
    cntNode.style.display = 'block';
    divNode.style.background = divNode.style.background.replace(/open./, 'close.');
  }
  else
  {
    cntNode.style.display = 'none';
    divNode.style.background = divNode.style.background.replace(/close./, 'open.');
  }
  
  return cntNode;
}

function __UpdateNode( divNode, dsp )
{
	var cntNode = document.getElementById(divNode.id.replace(/Img(.+)/, 'Content$1'));
	
	if(!cntNode) return;
	
	cntNode.style.display = dsp;
	if(dsp == 'block')
		divNode.style.background = divNode.style.background.replace(/open./, 'close.');
	else
		divNode.style.background = divNode.style.background.replace(/close./, 'open.');
	
	return cntNode;
}

function __ToggleChilds( divNode )
{
	var cntNode = __ToggleNode(divNode);
	if(!cntNode) return;
	var childs  = cntNode.getElementsByTagName('div');
	
	for(var i = 0; i != childs.length; ++i)
		if(/Img/.test(childs[i].id))
			__ToggleChilds(childs[i]);
}

function __UpdateChilds( divNode, dsp )
{
	var cntNode = __UpdateNode(divNode, dsp);
	if(!cntNode) return;
	var childs  = cntNode.getElementsByTagName('span');
	
	for(var i = 0; i != childs.length; ++i)
		if(/Img/.test(childs[i].id))
			__UpdateChilds(childs[i], dsp);
}

function ToggleNode( id )
{ __ToggleNode(document.getElementById(id)); }

function ShowContent( id )
{ __UpdateNode(document.getElementById(id), 'block'); }

function HideContent( id )
{ __UpdateNode(document.getElementById(id), 'none'); }

function ShowChilds( id )
{ __UpdateChilds(document.getElementById(id), 'block'); }

function HideChilds( id )
{ __UpdateChilds(document.getElementById(id), 'none'); }
