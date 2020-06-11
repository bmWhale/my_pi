#include <stdio.h>
#include <stdlib.h>
#include <string.h>
/*stack opt*/
struct node{
	char data;
	struct node *pre;
	struct node *next;
};

struct node *head, *tail;

int add_head(char c)
{
	struct node *new = (struct node*)malloc(sizeof(struct node));
	if(!new) return 0;
	new->data = c;
	new->next = NULL;
	new->pre = NULL;	
	if(!head)
	{
		tail=head=new;
	}else{
		new->next = head;
		head->pre = new;
		head = new;
	}
	return 1;
}

int add_tail(char c)
{
	struct node *new = (struct node*)malloc(sizeof(struct node));
	if(!new) return 0;
	new->data = c;
	new->next = NULL;
	new->pre = NULL;
	if(!head)
	{
		tail=head=new;
	}else{
		new->pre = tail;
		tail->next = new;
		tail = new;
	}
	return 1;
}

char pop_head()
{
	static char c=0;
	if(!head) return -1;
	c = head->data;
	struct node *tmp = head->next;
	free(head);
	head = tmp;
	head->pre = NULL;
	return c;
}

char pop_tail()
{
	static char c=0;
	if(!tail) return -1;
	c = tail->data;
	struct node *tmp = tail->pre;
	free(tail);
	tail = tmp;
	tail->next = NULL;
	return c;
}

int del_node(char c)
{
	struct node *tmp=head;
	while(tmp)
	{
		if(c==tmp->data)
		{
			(tmp->next)->pre=(tmp->pre);
			(tmp->pre)->next=(tmp->next);
			free(tmp);
			return 0;
		}
		tmp=tmp->next;
	}
	return -1;
}

int add_node_before(char src, char c)
{

	struct node *new=(struct node*)malloc(sizeof(struct node));
	new->data=c;
	struct node *tmp=head;
	while(tmp)
	{
		if(src==tmp->data)
		{
			(tmp->pre)?(tmp->pre)->next=new:(head = new);
			new->pre = tmp->pre;
			new->next = tmp;
			tmp->pre = new;
			return 0;
		}
		tmp=tmp->next;
	}
	return -1;
}

int print_all_nodes()
{
	struct node *tmp = head;
	while(tmp) { printf("%c",tmp->data); tmp=tmp->next;}
	printf("\n");
}

int pop_all_nodes()
{
	struct node *tmp = head;
	while(tmp)
	{ 
		printf("%c",tmp->data); tmp=tmp->next;
		free(head); head = tmp;
	}
	printf("\n");
}

int main(int argc, char *argv[])
{
	head=tail=NULL;
	char a[]={"hello_world"};
	unsigned int a_len = strlen(a);
	int i=0;
	for(i=0;i<a_len;i++)
	{
		add_tail(a[i]);
	}
	add_head(' ');
	for(i=a_len-1;i>=0;i--)
	{
		add_head(a[i]);
	}
	printf("\n");
	print_all_nodes();
	printf("pop head %c",pop_head());
	printf("%c",pop_head());
	printf("%c\n",pop_head());
	printf("pop tail %c",pop_tail());
	printf("%c",pop_tail());
	printf("%c\n",pop_tail());
	printf("del 'e' : %s\n",del_node('e')?"NOK":"OK");
	printf("del 'e' : %s\n",del_node('e')?"NOK":"OK");

	printf("add 'k' b4 'l': %s \n", add_node_before('l', 'k')?"NOK":"OK");
	printf("add 'k' b4 'l': %s \n", add_node_before('l', 'k')?"NOK":"OK");
	print_all_nodes();
	pop_all_nodes();
	return 0;

}
